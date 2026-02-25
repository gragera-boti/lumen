import Foundation

/// A placeholder configuration file for API keys.
///
/// In a production environment, you would typically fetch these from a secure backend,
/// store them in the Keychain, or inject them via environment secrets during the build.
///
/// For this implementation, paste your Together AI key here.
public enum APIKeys {
    /// Together AI Key for generating FLUX.1 backgrounds.
    /// Get one at: https://api.together.ai
    public static let togetherAI = "tgp_v1_1lIBlX0GBL1G58bXgwRL3ePsO-Z74oeeAZBvct1TXcg"
}
