import { apiInitializer } from "discourse/lib/api";
import AdBetweenPosts from "../components/ad-between-posts";

export default apiInitializer((api) => {
  api.renderAfterWrapperOutlet("post-article", AdBetweenPosts);
});
