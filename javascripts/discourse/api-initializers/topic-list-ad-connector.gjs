import { apiInitializer } from "discourse/lib/api";
import AdBetweenTopics from "../components/ad-between-topics";

export default apiInitializer("1.15.0", (api) => {
  api.renderInOutlet("after-topic-list-item", AdBetweenTopics);
});
