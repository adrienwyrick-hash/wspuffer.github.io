import Foundation
import Capacitor
import GameKit
import UIKit

@objc(GameCenterPlugin)
public class GameCenterPlugin: CAPPlugin, CAPBridgedPlugin, GKGameCenterControllerDelegate {
    public let identifier = "GameCenterPlugin"
    public let jsName = "GameCenter"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "authenticate",             returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isAuthenticated",          returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "submitScore",              returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showLeaderboard",          returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showAchievements",         returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "reportAchievement",        returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "resetAchievements",        returnType: CAPPluginReturnPromise)
    ]

    private let defaultLeaderboardID = "com.wyrickstudios.WSPuffer.bestscore"

    // MARK: - Authentication

    @objc func authenticate(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let player = GKLocalPlayer.local
            if player.isAuthenticated {
                call.resolve(self.playerPayload(player))
                return
            }
            player.authenticateHandler = { [weak self] viewController, error in
                guard let self = self else { return }
                if let viewController = viewController {
                    // Apple wants us to show the sign-in UI.
                    if let rootVC = self.bridge?.viewController {
                        rootVC.present(viewController, animated: true)
                    }
                    return
                }
                if let error = error {
                    call.reject(error.localizedDescription)
                    return
                }
                call.resolve(self.playerPayload(player))
            }
        }
    }

    @objc func isAuthenticated(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            call.resolve(self.playerPayload(GKLocalPlayer.local))
        }
    }

    private func playerPayload(_ p: GKLocalPlayer) -> [String: Any] {
        return [
            "authenticated": p.isAuthenticated,
            "displayName":   p.isAuthenticated ? p.displayName : "",
            "playerID":      p.isAuthenticated ? p.gamePlayerID : ""
        ]
    }

    // MARK: - Leaderboard

    @objc func submitScore(_ call: CAPPluginCall) {
        guard let score = call.getInt("score") else {
            call.reject("Missing score")
            return
        }
        let leaderboardID = call.getString("leaderboardID") ?? defaultLeaderboardID
        guard GKLocalPlayer.local.isAuthenticated else {
            call.reject("Not authenticated")
            return
        }
        if #available(iOS 14.0, *) {
            GKLeaderboard.submitScore(
                score, context: 0, player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            ) { error in
                if let error = error { call.reject(error.localizedDescription) }
                else { call.resolve(["submitted": true, "score": score]) }
            }
        } else {
            let report = GKScore(leaderboardIdentifier: leaderboardID)
            report.value = Int64(score)
            GKScore.report([report]) { error in
                if let error = error { call.reject(error.localizedDescription) }
                else { call.resolve(["submitted": true, "score": score]) }
            }
        }
    }

    @objc func showLeaderboard(_ call: CAPPluginCall) {
        let leaderboardID = call.getString("leaderboardID") ?? defaultLeaderboardID
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let rootVC = self.bridge?.viewController else {
                call.reject("No view controller available")
                return
            }
            let vc: GKGameCenterViewController
            if #available(iOS 14.0, *) {
                vc = GKGameCenterViewController(
                    leaderboardID: leaderboardID,
                    playerScope: .global,
                    timeScope: .allTime
                )
            } else {
                let legacy = GKGameCenterViewController()
                legacy.viewState = .leaderboards
                legacy.leaderboardIdentifier = leaderboardID
                vc = legacy
            }
            vc.gameCenterDelegate = self
            rootVC.present(vc, animated: true) {
                call.resolve(["presented": true])
            }
        }
    }

    // MARK: - Achievements

    @objc func showAchievements(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let rootVC = self.bridge?.viewController else {
                call.reject("No view controller available")
                return
            }
            let vc: GKGameCenterViewController
            if #available(iOS 14.0, *) {
                vc = GKGameCenterViewController(state: .achievements)
            } else {
                let legacy = GKGameCenterViewController()
                legacy.viewState = .achievements
                vc = legacy
            }
            vc.gameCenterDelegate = self
            rootVC.present(vc, animated: true) {
                call.resolve(["presented": true])
            }
        }
    }

    @objc func reportAchievement(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else {
            call.reject("Missing id")
            return
        }
        let percent = call.getDouble("percent") ?? 100.0
        let showsCompletionBanner = call.getBool("banner") ?? true

        guard GKLocalPlayer.local.isAuthenticated else {
            call.reject("Not authenticated")
            return
        }
        let achievement = GKAchievement(identifier: id)
        achievement.percentComplete = percent
        achievement.showsCompletionBanner = showsCompletionBanner
        GKAchievement.report([achievement]) { error in
            if let error = error { call.reject(error.localizedDescription) }
            else { call.resolve(["reported": true, "id": id, "percent": percent]) }
        }
    }

    @objc func resetAchievements(_ call: CAPPluginCall) {
        GKAchievement.resetAchievements { error in
            if let error = error { call.reject(error.localizedDescription) }
            else { call.resolve(["reset": true]) }
        }
    }

    // MARK: - GKGameCenterControllerDelegate

    public func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
