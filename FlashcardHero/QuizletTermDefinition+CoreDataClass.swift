//
//  QuizletTermDefinition+CoreDataClass.swift
//  FlashcardHero
//
//  Created by Jacob Foster Davis on 11/3/16.
//  Copyright © 2016 Zero Mu, LLC. All rights reserved.
//

import Foundation
import CoreData
import UIKit


public class QuizletTermDefinition: NSManagedObject {

    //TODO: have this object load the image from url when imageUrl is set or changed
    var isTransitioningImage = false
    
    var searchAttempts = 0 //tracks network attempts
    
    convenience init(withQuizletTermResult: QuizletGetTermResult, relatedSet: QuizletSet, context: NSManagedObjectContext){
        
        if let ent = NSEntityDescription.entity(forEntityName: "QuizletTermDefinition", in: context) {
            self.init(entity: ent, insertInto: context)
            
            //using the FlickrPhotoResult, populate this object
            if  let termId = withQuizletTermResult.id,
                let term = withQuizletTermResult.term,
                let definition = withQuizletTermResult.definition,
                let rank = withQuizletTermResult.rank {
                
                self.termId = Int64(termId)
                self.term = term
                self.definition = definition
                self.rank = Int64(rank)
                
                //image is optional or blank
                if let image = withQuizletTermResult.image {
                    
                    //TODO: add validation
                    //TODO: Don't hard code this
                    self.imageHeight = Int64((image["height"] as! NSNumber).intValue)
                    self.imageUrl = image["url"] as? String
                    self.imageWidth = Int64((image["width"] as! NSNumber).intValue)
                    
                    checkAndDownloadImage()
                }

                //add the related set
                self.quizletSet = relatedSet
                
            } else {
                //TODO: throw an error because everything wasn't as expected
            }
        } else {
            fatalError("Unable to find Entity name! (QuizletTermDefinition)")
        }
        
    }
    
    
    /******************************************************/
    /*************///MARK: - General Functions
    /******************************************************/
    
    func checkAndDownloadImage() {
        if self.imageData == nil && self.imageUrl != nil {
            downloadImageData()
        }
    }
    
    /******************************************************/
    /*************///MARK: - Network
    /******************************************************/
    
    func downloadImageData() {
        //download image data based on the URL
        
        guard self.imageUrl != nil else {
            return
        }
        
        //TODO: start activity spinner
        isTransitioningImage = true
        GCDBlackBox.runNetworkFunctionInBackground {
            let _ = QuizletClient.sharedInstance.taskForGETImage(filePath: self.imageUrl!) {
                (imageData, error) in
                GCDBlackBox.performUIUpdatesOnMain {
                    if let imageDataNS = imageData as NSData? {
                        
                        self.imageData = imageDataNS
                        print("Image data succesfully retireved and set")
                        
                        //try to set this image as the set thumbnail
                        self.quizletSet?.setThumbnailImage(imageData: imageDataNS)
                                                
                    } else if self.searchAttempts < 2 {
                        //search again
                        self.searchAttempts += 1
                        print("Retrying search for downloadImageData, search try \(self.searchAttempts)")
                        self.downloadImageData()
                    } else {
                        self.searchAttempts = 0
                        //tried twice, give user an error
                        print("Problem downloading image data")
                        //alertGenericNetworkError(vc: sender, errorString: (error?.localizedDescription)!)
                        
                    }
                    
                    //TODO: stop activity spinner
                    self.isTransitioningImage = false
                }//endUI updates on main
            }
        }//end background black box
    }
}
