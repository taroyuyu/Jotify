//
//  ColorPickerController.swift
//  Jotify
//
//  Created by Harrison Leath on 7/7/19.
//  Copyright © 2019 Harrison Leath. All rights reserved.
//

import ChromaColorPicker
import CoreData
import UIKit

class ColorPickerController: UIViewController {
    var notes: [Note] = []
    
    let defaults = UserDefaults.standard
    let defaultColor = UIColor(red: 0.62, green: 0.78, blue: 1, alpha: 1)
    var colorChanged = false
    
    lazy var brightnessSlider: ChromaBrightnessSlider = {
        let slider = ChromaBrightnessSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    lazy var colorPicker: ChromaColorPicker = {
        let colorPicker = ChromaColorPicker()
        colorPicker.delegate = self
        colorPicker.translatesAutoresizingMaskIntoConstraints = false
        return colorPicker
    }()
    
    lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.backgroundColor = UIColor.white
        contentView.layer.cornerRadius = 15
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        fetchData()
        setupClearNavigationBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    func setupView() {
        view.backgroundColor = defaultColor
        
        var image = UIImage(named: "cancel")
        image = image?.withRenderingMode(.alwaysOriginal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleCancel))
        
        navigationItem.setHidesBackButton(true, animated: true)
        
        let navigationBarHeight = navigationController!.navigationBar.frame.height
        
        colorPicker.addHandle(at: defaultColor)
        colorPicker.connect(brightnessSlider)
        
        view.addSubview(contentView)
        view.addSubview(colorPicker)
        view.addSubview(brightnessSlider)
        
        contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -navigationBarHeight).isActive = true
        contentView.widthAnchor.constraint(equalToConstant: 350).isActive = true
        contentView.heightAnchor.constraint(equalToConstant: 450).isActive = true
        
        colorPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        colorPicker.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -navigationBarHeight - 40).isActive = true
        colorPicker.widthAnchor.constraint(equalToConstant: 300).isActive = true
        colorPicker.heightAnchor.constraint(equalToConstant: 300).isActive = true
        
        brightnessSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        brightnessSlider.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 120).isActive = true
        brightnessSlider.widthAnchor.constraint(equalToConstant: 280).isActive = true
        brightnessSlider.heightAnchor.constraint(equalToConstant: 32).isActive = true

        setupClearNavigationBar()
        
        if defaults.bool(forKey: "darkModeEnabled") {
            contentView.backgroundColor = UIColor.grayBackground
        }
    }
    
    @objc func handleCancel() {
        if !colorChanged {
            StoredColors.staticNoteColor = defaultColor
            defaults.set(defaultColor, forKey: "staticNoteColor")
            setStaticColorForNotes()
        }
        self.playHapticFeedback()
        navigationController?.popViewController(animated: true)
    }
    
    func setupClearNavigationBar() {
        guard navigationController?.topViewController === self else { return }
        transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            self?.navigationController?.navigationBar.shadowImage = UIImage()
            self?.navigationController?.navigationBar.backgroundColor = .clear
            self?.navigationController?.navigationBar.barTintColor = self?.defaultColor
            self?.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            }, completion: nil)
    }
    
    func setStaticColorForNotes() {
        let writeNoteView = WriteNoteView()
        var newBackgroundColor = UIColor.grayBackground
        
        for note in notes {
            var newColor = String()
            
            if !defaults.bool(forKey: "useRandomColor") {
                newColor = "staticNoteColor"
                newBackgroundColor = defaults.color(forKey: "staticNoteColor") ?? UIColor.blue2
            }
            
            note.color = newColor
        }
        
        writeNoteView.backgroundColor = newBackgroundColor
        
        CoreDataManager.shared.enqueue { context in
            do {
                try context.save()
                
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    func fetchData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Note")
        fetchRequest.returnsObjectsAsFaults = false
        
        let sortDescriptor = NSSortDescriptor(key: "modifiedDate", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            notes = try managedContext.fetch(fetchRequest) as! [Note]
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        Themes().triggerSystemMode(mode: traitCollection)
        
        if defaults.bool(forKey: "darkModeEnabled") {
            contentView.backgroundColor = UIColor.grayBackground
        } else {
            contentView.backgroundColor = UIColor.white
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themes().setStatusBar(traitCollection: traitCollection)
    }
}

extension ColorPickerController: ChromaColorPickerDelegate {
    func colorPickerHandleDidChange(_ colorPicker: ChromaColorPicker, handle: ChromaColorHandle, to color: UIColor) {
        view.backgroundColor = color
        colorChanged = true
        
        defaults.set(color, forKey: "staticNoteColor")
        setStaticColorForNotes()
        
        StoredColors.staticNoteColor = color
        navigationController?.navigationBar.barTintColor = color
    }
    
}
