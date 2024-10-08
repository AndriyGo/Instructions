// Copyright (c) 2016-present Frédéric Maquin <fred@ephread.com> and contributors.
// Licensed under the terms of the MIT License.

import UIKit

@MainActor public class CoachMarkHelper {

    let instructionsRootView: InstructionsRootView
    let flowManager: FlowManager

    init(instructionsRootView: InstructionsRootView, flowManager: FlowManager) {
        self.instructionsRootView = instructionsRootView
        self.flowManager = flowManager
    }

    /// Returns a new coach mark with a cutout path set to be
    /// around the provided UIView. The cutout path will be slightly
    /// larger than the view and have rounded corners, however you can
    /// bypass the default creator by providing a block.
    ///
    /// The point of interest (defining where the arrow will sit, horizontally)
    /// will be the one provided.
    ///
    /// - Parameter view: the view around which create the cutoutPath
    /// - Parameter pointOfInterest: the point of interest toward which the arrow should point
    /// - Parameter bezierPathBlock: a block customizing the cutoutPath
    public func makeCoachMark(for view: UIView? = nil, pointOfInterest: CGPoint? = nil,
                              cutoutPathMaker: CutoutPathMaker? = nil) -> CoachMark {
        var coachMark = CoachMark()

        guard let view = view else {
            return coachMark
        }

        self.update(coachMark: &coachMark, usingView: view,
                    pointOfInterest: pointOfInterest, cutoutPathMaker: cutoutPathMaker)

        return coachMark
    }

    /// Provides default coach views.
    ///
    /// - Parameter arrow: `true` to return an instance of `CoachMarkArrowDefaultView`
    ///                        as well, `false` otherwise.
    /// - Parameter withNextText: `true` to show the ‘next’ pseudo-button,
    ///                           `false` otherwise.
    /// - Parameter arrowOrientation: orientation of the arrow (either .Top or .Bottom)
    ///
    /// - Returns: new instances of the default coach views.
    public func makeDefaultCoachViews(withArrow arrow: Bool = true,
                                      withNextText nextText: Bool = true,
                                      arrowOrientation: CoachMarkArrowOrientation? = .top)
    -> (bodyView: CoachMarkBodyDefaultView, arrowView: CoachMarkArrowDefaultView?) {

        var coachMarkBodyView: CoachMarkBodyDefaultView

        if nextText {
            coachMarkBodyView = CoachMarkBodyDefaultView()
        } else {
            coachMarkBodyView = CoachMarkBodyDefaultView(hintText: "", nextText: nil)
        }

        var coachMarkArrowView: CoachMarkArrowDefaultView?

        if arrow { coachMarkArrowView = makeDefaultArrow(withOrientation: arrowOrientation) }

        return (bodyView: coachMarkBodyView, arrowView: coachMarkArrowView)
    }

    /// Provides default coach views, can have a next label or just the message.
    ///
    /// - Parameter arrow: `true` to return an instance of
    ///                        `CoachMarkArrowDefaultView` as well, `false` otherwise.
    /// - Parameter arrowOrientation: orientation of the arrow (either .Top or .Bottom)
    /// - Parameter hintText: message to show in the CoachMark
    /// - Parameter nextText: text for the next label, if nil the CoachMark
    ///                       view will only show the hint text
    ///
    /// - Returns: new instances of the default coach views.
    public func makeDefaultCoachViews(withArrow arrow: Bool = true,
                                      arrowOrientation: CoachMarkArrowOrientation? = .top,
                                      hintText: String, nextText: String? = nil)
    -> (bodyView: CoachMarkBodyDefaultView, arrowView: CoachMarkArrowDefaultView?) {
        let coachMarkBodyView = CoachMarkBodyDefaultView(hintText: hintText, nextText: nextText)

        var coachMarkArrowView: CoachMarkArrowDefaultView?

        if arrow { coachMarkArrowView = makeDefaultArrow(withOrientation: arrowOrientation) }

        return (bodyView: coachMarkBodyView, arrowView: coachMarkArrowView)
    }

    /// Updates the currently stored coach mark with a cutout path set to be
    /// around the provided UIView. The cutout path will be slightly
    /// larger than the view and have rounded corners, however you can
    /// bypass the default creator by providing a block.
    ///
    /// The point of interest (defining where the arrow will sit, horizontally)
    /// will be the one provided.
    ///
    /// This method is expected to be used in the delegate, after pausing the display.
    /// Otherwise, there might not be such a thing as a "current coach mark".
    ///
    /// - Parameter view: the view around which create the cutoutPath
    /// - Parameter pointOfInterest: the point of interest toward which the arrow
    ///                              should point
    /// - Parameter bezierPathBlock: a block customizing the cutoutPath
    public func updateCurrentCoachMark(usingView view: UIView? = nil,
                                       pointOfInterest: CGPoint? = nil,
                                       cutoutPathMaker: CutoutPathMaker? = nil) {
        if !flowManager.isPaused || flowManager.currentCoachMark == nil {
            print("""
                  [ERROR] Something went wrong, did you call \
                  `updateCurrentCoachMark()` without pausing the controller first?
                  """)
            return
        }

        update(coachMark: &flowManager.currentCoachMark!, usingView: view,
               pointOfInterest: pointOfInterest, cutoutPathMaker: cutoutPathMaker)
    }

    /// Updates the given coach mark with a cutout path set to be
    /// around the provided UIView. The cutout path will be slightly
    /// larger than the view and have rounded corners, however you can
    /// bypass the default creator by providing a block.
    ///
    /// The point of interest (defining where the arrow will sit, horizontally)
    /// will be the one provided.
    ///
    /// - Parameter coachMark: the CoachMark to update
    /// - Parameter forView: the view around which create the cutoutPath
    /// - Parameter pointOfInterest: the point of interest toward which the arrow should point
    /// - Parameter bezierPathBlock: a block customizing the cutoutPath
    internal func update(coachMark: inout CoachMark,
                         usingView view: UIView? = nil, pointOfInterest: CGPoint?,
                         cutoutPathMaker: CutoutPathMaker? = nil) {
        guard let view = view else { return }

        let convertedFrame = instructionsRootView.convert(view.frame, from: view.superview)

        let bezierPath: UIBezierPath

        if let makeCutoutPathWithFrame = cutoutPathMaker {
            bezierPath = makeCutoutPathWithFrame(convertedFrame)
        } else {
            bezierPath = UIBezierPath(roundedRect: convertedFrame.insetBy(dx: -4, dy: -4),
                                      byRoundingCorners: .allCorners,
                                      cornerRadii: CGSize(width: 4, height: 4))
        }

        coachMark.cutoutPath = bezierPath

        if let pointOfInterest = pointOfInterest {
            coachMark.pointOfInterest = instructionsRootView.convert(pointOfInterest,
                                                                          from: view.superview)
        }
    }

    internal func makeDefaultArrow(withOrientation arrowOrientation: CoachMarkArrowOrientation?)
    -> CoachMarkArrowDefaultView {
        var arrowOrientation = arrowOrientation

        if arrowOrientation == nil {
            arrowOrientation = .top
        }

        return CoachMarkArrowDefaultView(orientation: arrowOrientation!)
    }
}

public typealias CutoutPathMaker = (_ frame: CGRect) -> UIBezierPath
