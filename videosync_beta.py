# -*- coding: utf-8 -*-
"""
videosync_beta.py

 For basler ace siries

@author: shige 2020/7/17
"""

import cv2
import tkinter
import PIL.Image, PIL.ImageTk
import nidaqmx
from pypylon import pylon
from tkinter import filedialog

class App:
    def __init__(self, window, window_title, video_source=0):
        self.window = window
        self.window.title(window_title)
        self.video_source = video_source

        #======================================================================
        # Camera Setup ========================================================
        
        # conecting to the first available camera
        self.camera = pylon.InstantCamera(pylon.TlFactory.GetInstance().CreateFirstDevice())

        # Grabing Continusely (video) with minimal delay
        self.camera.StartGrabbing(pylon.GrabStrategy_LatestImageOnly) 
        self.converter = pylon.ImageFormatConverter()

        # converting to opencv bgr format
        self.converter.OutputPixelFormat = pylon.PixelType_BGR8packed
        self.converter.OutputBitAlignment = pylon.OutputBitAlignment_MsbAligned
        
        
        #======================================================================
        # NIDaq Setup =========================================================
        
        with nidaqmx.Task() as task:
            task.do_channels.add_do_chan("cDAQ1Mod1/port0/line0")
            task.write(bool(0))               

        
        #======================================================================
        # GUI Setup ===========================================================

        # キャンバスとボタンを配置するフレームの作成と配置
        self.main_frame = tkinter.Frame(self.window)
        self.main_frame.pack()
        
        # キャンバスを配置するフレームの作成と配置
        self.canvas_frame = tkinter.Frame(self.main_frame)        
        self.canvas_frame.grid(column=1, row=1)
        
        
        # ユーザ操作用フレームの作成と配置
        self.operation_frame1 = tkinter.Frame(self.main_frame)
        self.operation_frame1.grid(column=1, row=2, sticky=tkinter.W)
        
        # ユーザ操作用フレームの作成と配置
        self.operation_frame2 = tkinter.Frame(self.main_frame)
        self.operation_frame2.grid(column=1, row=3, sticky=tkinter.W)
        
        # キャンバスの作成と配置
        self.canvas = tkinter.Canvas(
            self.canvas_frame,
            width  = self.camera.Width.GetValue(),
            height = self.camera.Height.GetValue(),
            background = "white"
        )        
        self.canvas.pack()
        
        # ファイル保存設定ボタンの作成と配置
        self.save_button = tkinter.Button(
            self.operation_frame1, 
            width=20, 
            text="File setting", 
            command=self.show_save_dialog
        )
        self.save_button.pack(padx=20, pady=10, side=tkinter.LEFT)
        
        self.savefilename_label = tkinter.Label(self.operation_frame1, text="")
        self.savefilename_label.pack(padx=20, pady=10, side=tkinter.LEFT)
        
        # 記録スタートボタンの作成と配置
        self.start_rec_button = tkinter.Button(
            self.operation_frame2, 
            width=20, 
            text="Start",
            state=tkinter.DISABLED,
            command=self.start_recording)
        self.start_rec_button.pack(padx=20, pady=10, side=tkinter.LEFT)
        
        # 記録ストップボタンの作成と配置
        self.stop_rec_button = tkinter.Button(
            self.operation_frame2, 
            width=20, 
            text="Stop", 
            state=tkinter.DISABLED,
            command=self.stop_recording)
        self.stop_rec_button.pack(padx=20, pady=10, side=tkinter.LEFT)
        

        #======================================================================
        # Main loop ===========================================================

        self.videorecording = 0

        # After it is called once, the update method will be automatically called every delay milliseconds
        self.delay = 25
        #self.update()

        self.window.mainloop()
        
        
        
    def show_save_dialog(self):
        fname = filedialog.asksaveasfilename(initialfile="*.avi")
        if fname:
            # Setting for Save Image
            fourcc = cv2.VideoWriter_fourcc('D','I','V','X')  #fourccを定義
            self.savevideo = cv2.VideoWriter(fname,fourcc, 30.0, (self.camera.Width.GetValue(),self.camera.Height.GetValue()))  #動画書込準備
            self.start_rec_button['state'] = tkinter.NORMAL
            self.save_button['state'] = tkinter.DISABLED
            self.savefilename_label['text'] = fname
        else:
            print("Cancel or X button was clicked.")



    def start_recording(self):       
        self.videorecording = 1
        self.stop_rec_button['state'] = tkinter.NORMAL
        self.start_rec_button['state'] = tkinter.DISABLED
        self.window.after(self.delay, self.update)
        
        
    
    def stop_recording(self):       
        self.videorecording = 0
        self.stop_rec_button['state'] = tkinter.DISABLED
        self.savevideo.release()
        self.window.after(self.delay, self.update)
        


    def update(self):
        if self.videorecording == 1:                        
            # Get a frame from the video source
            grabResult = self.camera.RetrieveResult(5000, pylon.TimeoutHandling_ThrowException)
            if grabResult.GrabSucceeded():
                # NI Daq signal
                with nidaqmx.Task() as task:
                    task.do_channels.add_do_chan("cDAQ1Mod1/port0/line0")
                    task.write(bool(1))      
                
                # Access the image data
                pylonimage = self.converter.Convert(grabResult)
                frame   = pylonimage.GetArray()
                self.img   = PIL.ImageTk.PhotoImage(PIL.Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)))
                self.canvas.create_image(0, 0, image = self.img, anchor = tkinter.NW)
                
                self.savevideo.write(frame) # frame の書き出し

                # NI Daq signal
                with nidaqmx.Task() as task:
                    task.do_channels.add_do_chan("cDAQ1Mod1/port0/line0")
                    task.write(bool(0))                            
                
        self.window.after(self.delay, self.update)



# Create a window and pass it to the Application object
App(tkinter.Tk(), "Tkinter and OpenCV")