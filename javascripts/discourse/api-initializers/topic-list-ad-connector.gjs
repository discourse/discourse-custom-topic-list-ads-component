import { apiInitializer } from "discourse/lib/api";
import AdBetweenTopics from "../components/ad-between-topics";

export default apiInitializer((api) => {
  api.renderInOutlet("after-topic-list-item", AdBetweenTopics);
});
