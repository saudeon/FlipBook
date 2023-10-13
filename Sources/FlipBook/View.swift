//
//  View.swift
//  
//
//  Created by Brad Gayman on 1/24/20.
//

#if os(OSX)
import AppKit
public typealias View = NSView
extension View {
    var scale: CGFloat {
        Screen.main?.backingScaleFactor ?? 1.0
    }
    
    func fb_makeViewSnapshot() -> Image? {
        let wasHidden = isHidden
        let wantedLayer = wantsLayer
        
        isHidden = false
        wantsLayer = true
                
        let width = Int(bounds.width * scale)
        let height = Int(bounds.height * scale)
        let imageRepresentation = NSBitmapImageRep(bitmapDataPlanes: nil,
                                                   pixelsWide: width,
                                                   pixelsHigh: height,
                                                   bitsPerSample: 8,
                                                   samplesPerPixel: 4,
                                                   hasAlpha: true,
                                                   isPlanar: false,
                                                   colorSpaceName: NSColorSpaceName.deviceRGB,
                                                   bytesPerRow: 0,
                                                   bitsPerPixel: 0)
        imageRepresentation?.size = bounds.size

        guard let imgRep = imageRepresentation,
              let context = NSGraphicsContext(bitmapImageRep: imgRep) else {
            return nil
        }

        layer?.presentation()?.render(in: context.cgContext)
        
        let image = NSImage(size: bounds.size)
        image.addRepresentation(imgRep)
        
        wantsLayer = wantedLayer
        isHidden = wasHidden
        return image
    }
}

#else
import UIKit
import AVFoundation
public typealias View = UIView

extension View {
    
    var scale: CGFloat {
        Screen.main.scale
    }
    
    func fb_makeViewSnapshot() -> Image? {

      // Check if we have an a view that includes an AVPlayerLayer.
      // If we do, we want to basically create a new view, insert it into the view with a captured frame.

      if let playerView = subviews.first(where: { $0.layer is AVPlayerLayer }),
         let avLayer = playerView.layer as? AVPlayerLayer,
         let player = avLayer.player,
         let asset = player.currentItem?.asset {
        let imageView = UIImageView(frame: playerView.frame)

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero

        guard
          let thumb = try? imageGenerator.copyCGImage(
            at: player.currentTime(),
            actualTime: nil) else { return nil }
        let image = UIImage(cgImage: thumb)
        imageView.image = image
        addSubview(imageView)
      }

      return UIGraphicsImageRenderer(size: bounds.size).image { _ in
        drawHierarchy(in: bounds, afterScreenUpdates: true)
      }
    }
}
#endif
