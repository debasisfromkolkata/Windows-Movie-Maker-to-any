/*Copyright (c) 2014 Debasis Halder (contact@debasishalder.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
package com.debasishalder.utility
{
	import flash.system.System;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	public class Wlmpparser
	{
		private var XML_Counter = 0;
		private var outputfolder:String;
		public var Command_Array:Array;
		private var File_List:Array = new Array  ;
		private var temp_Command_Array:Array;
		private var temp_File_List_Array:Array;
		private var XML_Array:Array;
		private var onComplete:Function;
		private var tempDir:File;
		private var tempDirPath:String;
		private var ListedFile_name:String = null;
		private var projectName:String = '';
		private var extesion_export:String;
		private var outputwidth:Number;
		private var outputheight:Number;
		private var tempFile:File;
		private var Quality:int;
		public function Wlmpparser()
		{
			// constructor code
		}
		public function ParseWlmp(ELMP: * ,output_dir:String,outputExtension:String,callBack:Function ,quality:int = 4,Width:Number = -1,Height:Number = -1)
		{
			outputfolder = output_dir;
			outputfolder = outputfolder.split('\\').join('/');
			onComplete = callBack;
			extesion_export = outputExtension;
			Quality = quality;
			outputwidth = Width;
			outputheight = Height;
			XML_Counter = 0;
			ListedFile_name = null;
			projectName = '';
			Command_Array = new Array();
			tempDir = File.createTempDirectory();
			tempDirPath = tempDir.nativePath;
			tempDirPath = tempDirPath.split('\\').join('/');
			tempDir = null;
			XML_Array = null;
			if (ELMP is Array)
			{
				XML_Array = ELMP;
			}
			if (XML_Array != null)
			{
				if (XML_Array[XML_Counter] is XML)
				{
					parse(XML_Array[XML_Counter]);
				}
				else
				{
					throw new Error("Not a valid wlmp file");
				}
			}
			else if (ELMP is XML)
			{
				parse(ELMP);
			}
			else
			{
				throw new Error("Not a valid wlmp file");
			}

		}
		private function parse(xmlContent:XML):void
		{

			var cmd = "";
			var path:Object = new Object  ;
			projectName +=  xmlContent. @ name;
			for (var s:int = 0; s < xmlContent.MediaItems.MediaItem.length(); s++)
			{
				var Filepath:String = xmlContent.MediaItems.MediaItem[s]. @ filePath;
				tempFile = new File(Filepath);
				if (! tempFile.exists)
				{
					throw new Error((Filepath + ' Not Exists'));
					return;
				}
				tempFile = null;
				path[xmlContent.MediaItems.MediaItem[s]. @ id] = Filepath;
			}
			for (var i:int = 0; i < xmlContent.Extents.VideoClip.length(); i++)
			{
				var xmlnode:XML = xmlContent.Extents.VideoClip[i];
				var ExtentID:String = xmlnode. @ extentID;
				var MediaItemID:String = xmlnode. @ mediaItemID;
				var inputFile:String = path[MediaItemID];
				inputFile = inputFile.split('\\').join('/');
				var file_name:String = getfilename(inputFile);
				var extension:String = getextension(inputFile);
				if (ListedFile_name == null)
				{
					ListedFile_name = tempDirPath + '/' + file_name + '.txt';
				}
				var outputfile:String = tempDirPath + '/' + file_name + '_' + ExtentID + '_' + XML_Counter + '_' + i + extension;
				cmd = 'ffmpeg -i "' + path[MediaItemID] + '" -vcodec copy -acodec copy -ss ' + xmlnode. @ inTime + ' -t ' + String(Number(xmlnode. @ outTime - xmlnode. @ inTime)) + ' "' + outputfile + '"\n';
				Command_Array[Number(ExtentID)] = cmd;
				File_List[Number(ExtentID)] = outputfile;
				System.disposeXML(xmlnode);
				xmlnode = null;
				ExtentID = null;
				MediaItemID = null;
				inputFile = null;
				extension = null;
				outputfile = null;
			}
			System.disposeXML(xmlContent);
			XML_Counter++;
			if ((XML_Array != null && XML_Counter < XML_Array.length))
			{
				if (XML_Array[XML_Counter] is XML)
				{
					parse(XML_Array[XML_Counter]);
				}
				else
				{
					throw new Error("Not a valid wlmp file");
				}
			}
			else
			{
				temp_Command_Array = new Array  ;
				temp_File_List_Array = new Array  ;
				for (i = 0; i < Command_Array.length; i++)
				{
					if (Command_Array[i] != null && Command_Array[i] != undefined && Command_Array[i] != '')
					{
						temp_Command_Array.push(Command_Array[i]);
						temp_File_List_Array.push(File_List[i]);
					}

				}
				Command_Array = temp_Command_Array;
				File_List = temp_File_List_Array;
				temp_Command_Array = null;
				temp_File_List_Array = null;
				cmd = 'file \'' + File_List.join('\'\nfile \'') + '\'';
				WriteString(new File(ListedFile_name),cmd);
				var outputName:String;
				if (outputwidth > 0 && outputheight > 0)
				{
					outputName = tempDirPath + '/' + projectName + '_FINAL' + extesion_export;
					Command_Array.push('ffmpeg -f concat -i "'+ListedFile_name+'" -c copy "'+outputName+'"');
					Command_Array.push('ffmpeg -i "'+outputName+'" -qscale '+Quality+' -s '+outputwidth+'x'+outputheight+' "'+outputfolder+'/'+projectName+'_FINAL_'+outputwidth+'x'+outputheight+'_'+extesion_export+'"');
				}
				else
				{
					outputName = outputfolder + '/' + projectName + '_FINAL' + extesion_export;
					Command_Array.push('ffmpeg -f concat -i "'+ListedFile_name+'" -c copy  -qscale '+Quality+' "'+outputName+'"');
				}
				if (onComplete != null)
				{
					onComplete(Command_Array,tempDirPath);
				}
			}
		}
		private function getextension(filename:String)
		{
			return filename.substring(filename.lastIndexOf('.'),filename.length);
		}
		private function getfilename(filename:String)
		{
			return filename.substring(filename.lastIndexOf('/')+1,filename.lastIndexOf('.'));
		}
		public function WriteString(file:File,S:String,FM=FileMode.WRITE)
		{
			var fileStream = new FileStream();
			fileStream.open(file,FM);
			fileStream.writeMultiByte(S,"ISO 8859-1");
			fileStream.close();
			fileStream = null;
		}
	}

}