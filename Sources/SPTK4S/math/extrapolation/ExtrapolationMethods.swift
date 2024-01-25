import Foundation

public enum ExtrapolationMethod {
    case THROW
    case LINEAR
    case NATURAL
    case CLAMP_TO_NAN
    case CLAMP_TO_ZERO
    case CLAMP_TO_END_POINT
}
