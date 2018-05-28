//
//  VideoCapture.swift
//  L-Systems
//
//  Created by Spizzace on 5/27/18.
//  Copyright © 2018 SpaiceMaine. All rights reserved.
//

import AVFoundation

typealias FrameId = UInt
typealias FrameInterval = UInt

enum VideoCaptureError: Error {
    case FailedToCreatePixelBuffer
    case FailedToCreatePixelBufferPool
    case FailedToGetPixelBufferPool
    case FailedToGetPixelBaseAddress
}

class VideoCapture {
    let frame_rate: UInt = 24
    let frame_count = 500
    let video_size: CGSize = CGSize(width: 1600, height: 1200)
    
    var video_writer: AVAssetWriter!
    var video_writer_input: AVAssetWriterInput!
    var pixel_buffer_adapter: AVAssetWriterInputPixelBufferAdaptor!
    
    var status: Status = .idle
    var error: Error? = nil
    
    private func destroy() {
        self.video_writer = nil
        self.video_writer_input = nil
        self.pixel_buffer_adapter = nil
    }
    
    func beginCapturingVideo()  {
        do {
            try self.createVideoAssetWriter()
            
            self.video_writer.startWriting()
            self.video_writer.startSession(atSourceTime: kCMTimeZero)
            
            //            if self.pixel_buffer_adapter.pixelBufferPool == nil {
            //                throw VideoCaptureError.FailedToCreatePixelBufferPool
            //            }
            
            self.status = .capturing
        } catch {
            print("beginCapturingVideo Fail: \(error)")
            
            self.error = error
            self.status = .error
            
            self.destroy()
            return
        }
    }
    
    func appendFrame(_ frame: FrameId, texture: MTLTexture) {
        guard self.status == .capturing else {
            print("Trying to append frame while not capturing")
            return
        }
        
        do {
            try self.append(frame, texture: texture)
        } catch {
            self.error = error
            self.status = .error
            
            self.video_writer_input.markAsFinished()
            self.video_writer.finishWriting {
                self.destroy()
            }
        }
    }
    
    func finishCapturingVideo() {
        self.video_writer_input.markAsFinished()
        self.video_writer.finishWriting {
            if let err = self.video_writer.error {
                print("Video Writing Complete: \(err)")
                self.error = err
                self.status = .error
            } else {
                print("Video Writing Complete")
                self.status = .done
            }
            
            self.destroy()
        }
    }
    
    private func createVideoAssetWriter() throws {
        let output_url = URL(fileURLWithPath: "/Users/SpaiceMaine/GoodKarmaCoding/LSystems Documents/capture/video.mov")
        
        // create writer
        do {
            self.video_writer = try AVAssetWriter(outputURL: output_url, fileType: .mov)
        } catch {
            print("Failed to create AVAssetWriter: \(error)")
            throw error
        }
        
        // create input
        let settings: [String:Any] = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : self.video_size.width,
            AVVideoHeightKey : self.video_size.height
        ]
        self.video_writer_input = AVAssetWriterInput(mediaType: .video,
                                                     outputSettings: settings)
        self.video_writer_input.expectsMediaDataInRealTime = false
        self.video_writer.add(self.video_writer_input)
        
        // buffer adapter
        let sourceBufferAttributes : [String : AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String : NSNumber(value: Int(self.video_size.width)),
            kCVPixelBufferHeightKey as String : NSNumber(value: Int(self.video_size.height)),
            ]
        self.pixel_buffer_adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.video_writer_input, sourcePixelBufferAttributes: sourceBufferAttributes)
    }
    
    private func append(_ frame: FrameId, texture: MTLTexture) throws {
        // Wait for input to be ready
        while !self.video_writer_input.isReadyForMoreMediaData {
            usleep(10_000)
        }
        
        try autoreleasepool {
            // Get Pixel Buffer
            /////////////
            //            guard let pixel_buffer_pool = self.pixel_buffer_adapter.pixelBufferPool else {
            //                throw VideoCaptureError.FailedToGetPixelBufferPool
            //            }
            
            let pixel_buffer_ptr = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
            defer {
                pixel_buffer_ptr.deallocate()
            }
            
            guard CVPixelBufferCreate(kCFAllocatorDefault,
                                      Int(self.video_size.width),
                                      Int(self.video_size.height),
                                      kCVPixelFormatType_32BGRA,
                                      nil,
                                      pixel_buffer_ptr) == kCVReturnSuccess,
                let pixel_buffer = pixel_buffer_ptr.pointee else {
                    throw VideoCaptureError.FailedToCreatePixelBuffer
            }
            
            // Get Pixel Data
            ////////////////////
            CVPixelBufferLockBaseAddress(pixel_buffer, CVPixelBufferLockFlags.init(rawValue: 0))
            defer {
                CVPixelBufferUnlockBaseAddress(pixel_buffer, CVPixelBufferLockFlags.init(rawValue: 0))
            }
            
            guard let base_buffer = CVPixelBufferGetBaseAddress(pixel_buffer) else {
                throw VideoCaptureError.FailedToGetPixelBaseAddress
            }
            texture.getBytes(base_buffer,
                             bytesPerRow: CVPixelBufferGetBytesPerRow(pixel_buffer),
                             from: MTLRegionMake2D(0, 0, texture.width, texture.height),
                             mipmapLevel: 0)
            
            // Append Pixel Data
            //////////////////////
            let frame_duration = CMTimeMake(1, Int32(self.frame_rate))
            let time = CMTimeMultiply(frame_duration, Int32(frame))
            self.pixel_buffer_adapter.append(pixel_buffer, withPresentationTime: time)
        }
    }
    
    enum Status {
        case idle, capturing, done, error
    }
}
