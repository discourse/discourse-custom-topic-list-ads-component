import { hbs } from "ember-cli-htmlbars";
import { withPluginApi } from "discourse/lib/plugin-api";
import { registerWidgetShim } from "discourse/widgets/render-glimmer";

export default {
  name: "initialize-topic-ad-connector",
  initialize() {
    registerWidgetShim(
      "custom-below-post-ad",
      "div.custom-below-post",
      hbs`<AdBetweenPosts @model={{@data}} />`
    );

    withPluginApi("0.1", (api) => {
      api.decorateWidget("post:after", (helper) => {
        return helper.attach("custom-below-post-ad", helper.widget.model);
      });
    });
  },
};
