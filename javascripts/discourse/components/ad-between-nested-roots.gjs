import Component from "@glimmer/component";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { service } from "@ember/service";
import { bind } from "discourse/lib/decorators";
import Category from "discourse/models/category";
import { i18n } from "discourse-i18n";

export default class AdBetweenNestedRoots extends Component {
  @service adConfigurator;
  @service router;

  currentAdData =
    settings.show_between_nested_roots !== 0
      ? this.adConfigurator.getAdForSlot(
          (this.args.index + 1) % settings.show_between_nested_roots === 0,
          { ad_placement: "between_posts" }
        )
      : null;

  intersectionObserver = null;
  adElement = null;

  get linkClasses() {
    const page = this.router.currentURL?.split("?")[0].replace(/^\//, "");
    const plausibleClass = `plausible-event-page=${page}`;
    return [plausibleClass, this.currentAdData?.customClasses]
      .filter(Boolean)
      .join(" ");
  }

  get shouldShow() {
    const categoryId = this.args.topic?.category_id;
    const category = Category.findById(categoryId);

    if (
      this.adConfigurator.shouldExcludeCategory(
        categoryId,
        category?.parent_category_id
      )
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
      <div
        {{didInsert this.setupAdImpressionTracking}}
        {{willDestroy this.cleanUp}}
        class="discourse-custom-ad-component --between-nested-roots"
      >
        <div>
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
        </div>
      </div>
    {{/if}}
  </template>
}
