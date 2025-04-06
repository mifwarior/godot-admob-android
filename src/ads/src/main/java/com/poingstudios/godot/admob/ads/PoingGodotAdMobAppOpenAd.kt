// MIT License
//
// Copyright (c) 2023-present Poing Studios
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

package com.poingstudios.godot.admob.ads

import android.util.ArraySet
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.appopen.AppOpenAd
import com.poingstudios.godot.admob.ads.converters.convertToAdRequest
import com.poingstudios.godot.admob.ads.converters.convertToGodotDictionary
import com.poingstudios.godot.admob.core.utils.LogUtils
import org.godotengine.godot.Dictionary
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class PoingGodotAdMobAppOpenAd(godot: Godot?) : org.godotengine.godot.plugin.GodotPlugin(godot) {
    private val appOpenAds = mutableListOf<AppOpenAd?>()
    
    override fun getPluginName(): String {
        return this::class.simpleName.toString()
    }

    override fun getPluginSignals(): MutableSet<SignalInfo> {
        val signals: MutableSet<SignalInfo> = ArraySet()
        signals.add(SignalInfo("on_app_open_ad_failed_to_load", Integer::class.java, Dictionary::class.java))
        signals.add(SignalInfo("on_app_open_ad_loaded", Integer::class.java))

        signals.add(SignalInfo("on_app_open_ad_clicked", Integer::class.java))
        signals.add(SignalInfo("on_app_open_ad_dismissed_full_screen_content", Integer::class.java))
        signals.add(SignalInfo("on_app_open_ad_failed_to_show_full_screen_content", Integer::class.java, Dictionary::class.java))
        signals.add(SignalInfo("on_app_open_ad_impression", Integer::class.java))
        signals.add(SignalInfo("on_app_open_ad_showed_full_screen_content", Integer::class.java))
        return signals
    }

    @UsedByGodot
    fun create() : Int {
        val uid = appOpenAds.size
        appOpenAds.add(null)
        return uid
    }

    @UsedByGodot
    fun load(adUnitId : String, adRequestDictionary : Dictionary, keywords : Array<String>, uid: Int, orientation: Int = AppOpenAd.APP_OPEN_AD_ORIENTATION_PORTRAIT) {
        activity!!.runOnUiThread {
            LogUtils.debug("loading app open ad")
            val adRequest = adRequestDictionary.convertToAdRequest(keywords)

            AppOpenAd.load(activity!!,
                adUnitId, adRequest, orientation, object : AppOpenAd.AppOpenAdLoadCallback() {
                    override fun onAdFailedToLoad(loadAdError: LoadAdError) {
                        emitSignal("on_app_open_ad_failed_to_load", uid, loadAdError.convertToGodotDictionary())
                    }
                    override fun onAdLoaded(ad: AppOpenAd) {
                        appOpenAds[uid] = ad
                        ad.fullScreenContentCallback = object: FullScreenContentCallback() {
                            override fun onAdClicked() {
                                LogUtils.debug("App Open Ad was clicked.")
                                emitSignal("on_app_open_ad_clicked", uid)
                            }

                            override fun onAdDismissedFullScreenContent() {
                                LogUtils.debug("App Open Ad dismissed fullscreen content.")
                                appOpenAds[uid] = null
                                emitSignal("on_app_open_ad_dismissed_full_screen_content", uid)
                            }

                            override fun onAdFailedToShowFullScreenContent(adError: AdError) {
                                LogUtils.debug("App Open Ad failed to show fullscreen content.")
                                appOpenAds[uid] = null
                                emitSignal("on_app_open_ad_failed_to_show_full_screen_content", uid, adError.convertToGodotDictionary())
                            }

                            override fun onAdImpression() {
                                LogUtils.debug("App Open Ad recorded an impression.")
                                emitSignal("on_app_open_ad_impression", uid)
                            }

                            override fun onAdShowedFullScreenContent() {
                                LogUtils.debug("App Open Ad showed fullscreen content.")
                                emitSignal("on_app_open_ad_showed_full_screen_content", uid)
                            }
                        }
                        emitSignal("on_app_open_ad_loaded", uid)
                    }
                }
            )
        }
    }

    @UsedByGodot
    fun show(uid : Int) {
        activity!!.runOnUiThread {
            appOpenAds[uid]?.show(activity!!)
        }
    }

    @UsedByGodot
    fun destroy(uid : Int) {
        LogUtils.debug("DESTROYING ${javaClass.simpleName}")
        appOpenAds[uid] = null //just set to null in order to try to clean up memory
    }
}
