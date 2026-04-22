import Component from "@glimmer/component";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { service } from "@ember/service";
import { bind } from "discourse/lib/decorators";
import { i18n } from "discourse-i18n";

export default class AdBetweenTopics extends Component {
  @service adConfigurator;
  @service router;

  currentAdData = this.adConfigurator.getAdForSlot(
    (this.args.index + 1) % settings.show_between_topics === 0,
    { ad_placement: "between_topics" }
  );

  intersectionObserver = null;
  adElement = null;

  get linkClasses() {
    const page = this.router.currentRouteName
      .replace(/^discovery\./, "")
      .split(".")[0];
    const plausibleClass = `plausible-event-page=${page}`;
    return [plausibleClass, this.currentAdData?.customClasses]
      .filter(Boolean)
      .join(" ");
  }

  get shouldShow() {
    const isDiscovery = this.router.currentRouteName.includes("discovery");
    if (!isDiscovery) {
      return false;
    }

    const categoryId = this.router.currentRoute.attributes?.category?.id;
    const parentCategoryId =
      this.router.currentRoute.attributes?.category?.parent_category_id;

    if (
      this.adConfigurator.shouldExcludeCategory(categoryId, parentCategoryId)
    ) {
      return false;
    }

    return !!this.currentAdData;
  }

  @bind
  handleAdIntersection(entries, observer) {
    entries.forEach((entry) => {
      if (entry.isIntersecting && this.currentAdData?.finalLink) {
        const adDataForAnalytics = {
          ad_id: this.currentAdData.id,
          ad_text_snippet: this.currentAdData.text,
          ad_link: this.currentAdData.finalLink,
        };

        this.adConfigurator.trackImpression(adDataForAnalytics);

        observer.unobserve(this.adElement);
      }
    });
  }

  @action
  setupAdImpressionTracking(element) {
    this.adElement = element;
    this.intersectionObserver?.disconnect();

    if (this.currentAdData && this.adElement) {
      const observerOptions = {
        root: null,
        rootMargin: "0px",
        threshold: 0.7, // 70% visible
      };

      this.intersectionObserver = new IntersectionObserver(
        this.handleAdIntersection,
        observerOptions
      );
      this.intersectionObserver.observe(this.adElement);
    }
  }

  @action
  cleanUp() {
    this.intersectionObserver?.disconnect();
    this.adElement = null;
  }

  <template>
    {{#if this.shouldShow}}
      <tr
        class="discourse-custom-ad-component --between-topics"
        {{didInsert this.setupAdImpressionTracking}}
        {{willDestroy this.cleanUp}}
      >
        <td colspan="100%">
          {{#if this.currentAdData.link}}
            <a
              href={{this.currentAdData.finalLink}}
              target="_blank"
              rel="noopener noreferrer nofollow sponsored"
              class={{this.linkClasses}}
            >
              <span class="disclosure">
                {{i18n (themePrefix "disclosure")}}
              </span>
              <span class="text-content">{{this.currentAdData.text}}</span>
            </a>
          {{/if}}
        </td>
      </tr>
    {{/if}}
  </template>
}
