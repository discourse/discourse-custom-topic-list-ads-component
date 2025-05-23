import { tracked } from "@glimmer/tracking";
import Service, { service } from "@ember/service";

function _doesUserMatchGroupCriteria(
  groupString,
  currentUserGroups,
  isUserAnon,
  isUserStaff
) {
  if (!groupString || groupString.trim() === "") {
    return false;
  }

  const adRuleGroups = groupString
    .split(",")
    .map((g) => g.trim().toLowerCase());

  if (adRuleGroups.includes("anon") && isUserAnon) {
    return true;
  }
  if (adRuleGroups.includes("staff") && isUserStaff) {
    return true;
  }
  if (currentUserGroups.some((userGroup) => adRuleGroups.includes(userGroup))) {
    return true;
  }
  return false;
}

export default class AdConfigurator extends Service {
  @service currentUser;

  @tracked _eligibleAds = [];

  _randomStartIndex = 0;
  _currentIndex = 0;
  _isInitialized = false;

  get isReady() {
    return this._isInitialized;
  }

  get eligibleAdsCount() {
    return this._eligibleAds.length;
  }

  initializeIfNeeded() {
    if (this._isInitialized) {
      return;
    }

    const allAdsConfig = settings.ads ? settings.ads : [];

    if (!allAdsConfig.length) {
      this._isInitialized = true;
      return;
    }

    const currentUserGroups = this.currentUser
      ? this.currentUser.groups.map((g) => g.name.toLowerCase())
      : [];
    const isUserStaff = this.currentUser ? this.currentUser.staff : false;
    const isUserAnon = !this.currentUser;

    this._eligibleAds = allAdsConfig
      .filter((ad) => {
        let shouldBeIncluded;
        let shouldBeExcluded = false;

        if (ad.include_groups?.trim() !== "") {
          shouldBeIncluded = _doesUserMatchGroupCriteria(
            ad.include_groups,
            currentUserGroups,
            isUserAnon,
            isUserStaff
          );
        } else {
          shouldBeIncluded = true; // if no group, include by default
        }

        if (ad.exclude_groups?.trim() !== "") {
          shouldBeExcluded = _doesUserMatchGroupCriteria(
            ad.exclude_groups,
            currentUserGroups,
            isUserAnon,
            isUserStaff
          );
        }

        return shouldBeIncluded && !shouldBeExcluded;
      })
      .map((ad) => {
        return { ...ad, finalLink: this._buildFinalLink(ad) };
      });

    if (this._eligibleAds.length > 0) {
      this._randomStartIndex = Math.floor(
        Math.random() * this._eligibleAds.length
      );
      this._currentSequentialIndex = this._randomStartIndex;
    }

    this._isInitialized = true;
  }

  getNextAd() {
    if (!this._isInitialized) {
      this.initializeIfNeeded();
    }

    if (this._eligibleAds.length === 0) {
      return;
    }

    const adToServe = this._eligibleAds[this._currentIndex];

    this._currentIndex = (this._currentIndex + 1) % this._eligibleAds.length;

    return adToServe;
  }

  _buildFinalLink(adData) {
    if (!adData) {
      return;
    }

    try {
      let url = new URL(adData.link);

      Object.keys(adData).forEach((key) => {
        if (key.startsWith("utm_") && adData[key]) {
          url.searchParams.append(key, adData[key]);
        }
      });

      return url.toString();
    } catch {
      return null;
    }
  }
}
