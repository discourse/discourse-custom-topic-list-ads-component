# Custom ads

Create custom text ads to display on the Discourse topic list and between posts.

This currently supports [Plausible](https://plausible.io/) for impression tracking. Note that you'll need to make sure the relevant Plausible scripts are present, for example:

```
<script defer data-domain="meta.discourse.org" src="https://www.discourse.org/js/script.outbound-links.tagged-events.js"></script>
```
