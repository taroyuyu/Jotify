//
//  NoteCollectionController.swift
//  Zurich
//
//  Created by Harrison Leath on 1/12/21.
//

import UIKit
import Blueprints
import XLActionController

class NoteCollectionController: UICollectionViewController {
    //update collection view when model changes
    var noteCollection: NoteCollection? {
        didSet {
            if isViewLoaded {
                collectionView.reloadData()
            }
        }
    }
    
    //layout for collectionView
    let iOSLayout = VerticalBlueprintLayout(
        itemsPerRow: 2.0,
        minimumInteritemSpacing: 10,
        minimumLineSpacing: 15,
        sectionInset: EdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
        stickyHeaders: false,
        stickyFooters: false)
    
    let iPadOSLayout = VerticalBlueprintLayout(
        itemsPerRow: 3.0,
        minimumInteritemSpacing: 10,
        minimumLineSpacing: 15,
        sectionInset: EdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
        stickyHeaders: false,
        stickyFooters: false)
    
    //life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setupNavigationBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
    }
    
    //view configuration
    func setupViewElements() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            collectionView.setCollectionViewLayout(iPadOSLayout, animated: true)
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            collectionView.setCollectionViewLayout(iOSLayout, animated: true)
        }
        collectionView.backgroundColor = UIColor(red: 40/255, green: 40/255, blue: 40/255, alpha: 1)
        collectionView.register(SavedNoteCell.self, forCellWithReuseIdentifier: "SavedNoteCell")
    }
    
    func setupNavigationBar() {
        navigationItem.title = "Saved Notes"
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = UIColor(red: 40/255, green: 40/255, blue: 40/255, alpha: 1)
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    //action handlers
    @objc func longTouchHandler(sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: collectionView)
        let indexPath = collectionView.indexPathForItem(at: location)
        
        let actionController = SkypeActionController()
        actionController.backgroundColor = .systemBlue
        actionController.addAction(Action("Delete note", style: .default, handler: { _ in
            DataManager.deleteNote(docID: (self.noteCollection?.notes[indexPath!.row].uid)!) { _ in }
            //display error in UI
        }))
        actionController.addAction(Action("Cancel", style: .cancel, handler: nil))
        present(actionController, animated: true, completion: nil)
    }
    
    //collectionView Logic
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return noteCollection?.notes.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SavedNoteCell", for: indexPath) as? SavedNoteCell else { fatalError("Wrong cell class dequeued") }
        
        cell.textLabel.text = noteCollection?.notes[indexPath.row].content
        cell.dateLabel.text = noteCollection?.notes[indexPath.row].timestamp.getDate()
        cell.backgroundColor = .systemBlue
        
        cell.layer.cornerRadius = 5
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
    
        cell.contentView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longTouchHandler(sender:))))
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.playHapticFeedback()
        let controller = EditingController()
        controller.note = (noteCollection?.notes[indexPath.row])!
        controller.noteCollection = noteCollection
        navigationController?.pushViewController(controller, animated: true)
    }
    
    //traitcollection: dynamic iPad layout and light/dark mode support
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.horizontalSizeClass == .compact {
            iPadOSLayout.itemsPerRow = 1.0
        } else if traitCollection.horizontalSizeClass == .regular {
            iPadOSLayout.itemsPerRow = 3.0
        }
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

extension NoteCollectionController: CollectionViewFlowLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 0
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            height = 120
        } else {
            height = 110
        }
        
        return CGSize(width: UIScreen.main.bounds.width, height: height)
    }
}
