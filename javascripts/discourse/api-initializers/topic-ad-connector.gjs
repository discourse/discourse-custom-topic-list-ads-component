import { apiInitializer } from "discourse/lib/api";
import AdBetweenNestedRoots from "../components/ad-between-nested-roots";
import AdBetweenPosts from "../components/ad-between-posts";

export default apiInitializer((api) => {
  api.renderAfterWrapperOutlet("post-article", AdBetweenPosts);
  api.renderInOutlet("nested-roots-between", AdBetweenNestedRoots);
});
