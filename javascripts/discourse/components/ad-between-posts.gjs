import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { service } from "@ember/service";
import { bind } from "discourse/lib/decorators";
import Category from "discourse/models/category";
import { i18n } from "discourse-i18n";

export default class AdBetweenPosts extends Component {
  @service adConfigurator;
  @service router;

  @tracked currentAdData;

  intersectionObserver = null;
  adElement = null;

  constructor() {
    super(...arguments);
    this.adConfigurator.initializeIfNeeded();

    if (settings.show_between_posts !== 0) {
      this.currentAdData = this.adConfigurator.getAdForSlot(
        this.args.post?.post_number === 1 ||
          this.args.post?.post_number % settings.show_between_posts === 0,
        { ad_placement: "between_posts" }
      );
    }
  }

  get shouldShow() {
    const categoryId = this.args.post?.topic?.category_id;
    const category = Category.findById(categoryId);
    const parentCategoryId = category?.parent_category_id;

    if (settings.exclude_categories) {
      const excludedCategories = settings.exclude_categories
        .split("|")
        .map((cat) => parseInt(cat, 10));
      if (
        excludedCategories.includes(categoryId) ||
        excludedCategories.includes(parentCategoryId)
      ) {
        return false;
      }
    }

    return !!this.currentAdData;
  }

  get afterLastPost() {
    return (
      this.args.post?.topic.highest_post_number === this.args.post?.post_number
    );
  }

  @bind
  handleAdIntersection(entries, observer) {
    entries.forEach((entry) => {
      if (
        entry.isIntersecting &&
        this.currentAdData &&
        this.currentAdData.finalLink
      ) {
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
      <div
        class="discourse-custom-ad-component --between-posts
          {{if this.afterLastPost '--last-post'}}"
        {{didInsert this.setupAdImpressionTracking}}
        {{willDestroy this.cleanUp}}
        {{didInsert this.setupAdImpressionTracking}}
        {{willDestroy this.cleanUp}}
      >
        <div>
          {{#if this.currentAdData.link}}
            <a
              href={{this.currentAdData.finalLink}}
              target="_blank"
              rel="noopener noreferrer nofollow sponsored"
              class={{this.currentAdData.customClasses}}
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
