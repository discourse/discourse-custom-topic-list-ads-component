import { apiInitializer } from "discourse/lib/api";
import AdBetweenPosts from "../components/ad-between-posts";

export default apiInitializer("1.15.0", (api) => {
  api.renderAfterWrapperOutlet("post-article", AdBetweenPosts);
});
