import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { bind } from "discourse/lib/decorators";

export default class AdBetweenTopics extends Component {
  @service adConfigurator;
  @service router;

  @tracked currentAdData = null;

  intersectionObserver = null;
  adElement = null;

  constructor() {
    super(...arguments);

    this.adConfigurator.initializeIfNeeded();
    this._adForThisSlot();
  }

  _adForThisSlot() {
    const isNthItem =
      (this.args.outletArgs.index + 1) % settings.show_between_every === 0;

    if (
      isNthItem &&
      this.adConfigurator.isReady &&
      this.adConfigurator.eligibleAdsCount > 0
    ) {
      this.currentAdData = this.adConfigurator.getNextAd();
    } else {
      this.currentAdData = null;
    }
  }

  get shouldShow() {
    const category = this.router.currentRoute.attributes?.category?.id;
    const parentCategory =
      this.router.currentRoute.attributes?.category?.parent_category_id;

    if (settings.exclude_categories) {
      const excludedCategories = settings.exclude_categories
        .split("|")
        .map((cat) => parseInt(cat, 10));
      if (
        excludedCategories.includes(category) ||
        excludedCategories.includes(parentCategory)
      ) {
        return false;
      }
    }

    return !!this.currentAdData;
  }

  @bind
  handleAdIntersection(entries, observer) {
    entries.forEach((entry) => {
      if (entry.isIntersecting && this.currentAdData) {
        const adIdentifier =
          this.currentAdData.id ||
          (this.currentAdData.text
            ? this.currentAdData.text.trim()
            : "unknown");

        console.log(`Ad with text '${adIdentifier}' is visible!`);

        // send plausible impression tracking event here

        observer.unobserve(this.adElement);
      }
    });
  }

  @action
  setupAdImpressionTracking(element) {
    this.adElement = element;

    if (this.intersectionObserver) {
      this.intersectionObserver.disconnect();
    }

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
    if (this.intersectionObserver) {
      this.intersectionObserver.disconnect();
    }
    this.adElement = null;
  }

  <template>
    {{#if this.shouldShow}}
      <tr
        class="discourse-custom-ad-component"
        {{didInsert this.setupAdImpressionTracking}}
        {{willDestroy this.cleanUp}}
      >
        <td colspan="100%">
          {{#if this.currentAdData.link}}
            <a
              href={{this.currentAdData.finalLink}}
              target="_blank"
              rel="noopener sponsored nofollow"
            >
              {{icon "rectangle-ad"}}
              {{this.currentAdData.text}}
            </a>
          {{/if}}
        </td>
      </tr>
    {{/if}}
  </template>
}
