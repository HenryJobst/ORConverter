#!/usr/bin/ruby
require 'rubygems'
require 'Qt'
require 'launchy'
require "i18n"
require "time"

require_relative "iof_result_list_reader"
require_relative "points_calculator"
require_relative "standard_html_result_report"
require_relative "fog_cup_standard_html_report"

I18n.load_path = Dir.glob("config/locales/*.yml")
I18n.locale = "de"

WIDTH = 400
HEIGHT = 150

class QtApp < Qt::Widget

  slots 'on_calculate()' ,
        'setOpenFileName()'

  def initialize
    super

    setWindowTitle "Nebel-Cup Punkte Berechnung"

    resize WIDTH, HEIGHT

    init_ui

    center
    show
  end

  def center
    qdw = Qt::DesktopWidget.new

    screenWidth = qdw.width
    screenHeight = qdw.height

    x = (screenWidth - WIDTH) / 2
    y = (screenHeight - HEIGHT) / 2

    move x, y
  end

  def createButton(text, member)
    button = Qt::PushButton.new(text)
    connect(button, SIGNAL('clicked()'), self, member)
    return button
  end

  def init_ui
    
    frameStyle = Qt::Frame::Sunken | Qt::Frame::Panel

    label = Qt::Label.new
    label.setText "Ergebnisdatei:"
    @openFileNameLabel = Qt::Label.new
    @openFileNameLabel.frameStyle = frameStyle
    openFileNameButton = Qt::PushButton.new(tr("&Laden"))
    connect(openFileNameButton, SIGNAL('clicked()'), self, SLOT('setOpenFileName()'))

    vbox = Qt::VBoxLayout.new self

    hbox_file = Qt::HBoxLayout.new
    hbox_file.addWidget label, 0, Qt::AlignLeft
    hbox_file.addWidget @openFileNameLabel
    hbox_file.addWidget openFileNameButton

    vbox.addStretch 1

    vbox.addLayout hbox_file

    vbox.addStretch 1

    treeview = Qt::TreeView.new
    #treeview.model = model
    treeview.windowTitle = "Simple Tree Model"

    vbox.addStretch 1


    @calculateButton = createButton(tr("Be&rechnen"), SLOT('on_calculate()'))
    @quitButton = createButton(tr("&Beenden"), SLOT('close()'))

    hbox_action = Qt::HBoxLayout.new
    hbox_action.addWidget @calculateButton, 1, Qt::AlignLeft
    hbox_action.addWidget @quitButton, 1, Qt::AlignRight
    vbox.addLayout hbox_action

  end

  def on_changed text
    @label.setText text
  end

  def on_calculate
    iof_result_list_reader = IofResultListReader.new([@openFileNameLabel.text], true)
    PointsCalculator.new(iof_result_list_reader.events, :nebel, true)
    iof_result_list_reader.simple_output(true)
    reports = StandardHtmlResultReport.new(iof_result_list_reader, true, nil, nil)
    reports.results.each do |result|
      Launchy.open(result)
    end   
    
    actual_year = Time.now.strftime("%Y")
    cup_name = "Nebel-Cup #{actual_year}"
    cup = CupCalculation.new(cup_name, actual_year, iof_result_list_reader.events, true, :nebel)
    linked_resources = true
    FogCupStandardHtmlReport.new(cup, linked_resources, true, nil, nil)
        
  end

  def setOpenFileName()
    fileName = Qt::FileDialog.getOpenFileName(self,
                                              tr("Ergebnisdatei"),
                                              @openFileNameLabel.text,
                                              tr("XML-Files (*.xml)"))
    if !fileName.nil?
      @openFileNameLabel.text = fileName
    end
  end
end

app = Qt::Application.new ARGV
QtApp.new
app.exec