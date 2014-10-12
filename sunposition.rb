=begin
Copyright (c) 2009 Gabriel Miller

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
=end
####################################
##############  TODO  #################
#
#
#
####################################

require "sketchup.rb"
filename="sunposition.rb"

######################################
##### a few classes
######################################
class Numeric
    #Degrees to radians.
    def to_rad
        self * Math::PI / 180.0
    end
    #Radians to degrees.
    def to_deg
        self * 180.0 / Math::PI
    end
  end
#class Float
#    alias_method :round_orig, :round
#    def round(n=0)
#        (self * (10.0 ** n)).round_orig * (10.0 ** (-n))
#    end
#end
class String
	# - - - - - - - - - - -
	# to_f doesn't handle comma ","
	# - - - - - - - - - - -
	def to_fl
		if self.include?(",")
			return self.gsub(",",".").to_f
		else
			return self.to_f
		end
	end
end
######################################
##### HERE IT COMES
######################################
module SUNPOSITION

def SUNPOSITION.startsunposition
	Sketchup.set_status_text "elegir opciones..."
	model = Sketchup.active_model
	prompts = [
		"Su latitud? (N = + ) (S = - )",
		"Su longitud? (E = + ) (W = - )",
		"Sol bajo horizonte?",
		"Época del año?",
		"Trazar sol como...",
		"Trazar líneas hacia origen?",
		"Distancia al sol?"
	]
	defaults = [
    (Sketchup.read_default "SUNPOSITION", "latitude", "44.123"),
    (Sketchup.read_default "SUNPOSITION", "longitude", "44.123"),
		(Sketchup.read_default "SUNPOSITION", "sunbelow", "No"),
		(Sketchup.read_default "SUNPOSITION", "time", "Today"),
		(Sketchup.read_default "SUNPOSITION", "sunas", "a circle (filled)"),
		(Sketchup.read_default "SUNPOSITION", "linestoorig", "No"),
		(Sketchup.read_default "SUNPOSITION", "distance", "5000")
	]
	#input = UI.inputbox prompts, defaults, "Latitude and Longitude Input (Use Decimal Degrees)/Settings "
	list = [
		"",
		"",
		"Si|No",
		"Hoy|Solsticio verano/Invierno en hemisferio sur|Equinoccio|Solsticio invierno/Verano en hemisferio sur|Elegir una fecha determinada",
		"una esfera (no recomendada en computadoras lentas)|un círculo (lleno)|un arco (línea)",
		"Si|No",
		"5000|10000|25000|50000|100000|"
	]
	input = UI.inputbox prompts, defaults, list, "Latitude and Longitude Input (Use Decimal Degrees) and other Settings"
	return if !input	#if canceled
  Sketchup.write_default "SUNPOSITION", "latitude", input[0]
  Sketchup.write_default "SUNPOSITION", "longitude", input[1]
	Sketchup.write_default "SUNPOSITION", "sunbelow", input[2]
	Sketchup.write_default "SUNPOSITION", "time", input[3]
	Sketchup.write_default "SUNPOSITION", "sunas", input[4]
	Sketchup.write_default "SUNPOSITION", "linestoorig", input[5]
	Sketchup.write_default "SUNPOSITION", "distance", input[6]
	Sketchup.set_status_text "trazando..."
	if !input.nil?
		latitude = input[0].to_f
		longitude = input[1].to_f
		belowhoriz = input[2].downcase
		#Making this number either bigger or smaller moves the sun either farther or closer
		hyp = input[6].to_i
	end
	#Longitude in Hours
	longitude = (longitude*-1)/15
	###############################
 # Begin Julian Day Calculation (Meeus Pages 59-61) vvvv
	t = Time.now	
	y = t.gmtime.year
	m = t.gmtime.month
  d =  t.gmtime.hour/24.to_f + t.gmtime.min/1440.to_f + t.gmtime.sec/86400.to_f
	#Input from user
	case input[3]
		when 'Today'
			d += t.gmtime.day
		when 'Summer Solstice/Winter in Southern Hemisphere'
			m = 6
			d += 21
		when 'Winter Solstice/Summer in Southern Hemisphere'
			m = 12
			d += 21
    when 'Equinox'
      m = 3
      d += 20
		else
			prompts = [
				"Year", 
				"Month", 
				"Day", 
        "Hour", 
				"Minute", 
				"Time Zone",
        "Save Output "
			]
			defaults = [
				(Sketchup.read_default "SUNPOSITION", "year", "2014"), 
				(Sketchup.read_default "SUNPOSITION", "month", "10"), 
				(Sketchup.read_default "SUNPOSITION", "day", "10"), 
				(Sketchup.read_default "SUNPOSITION", "hour", "12"), 
				(Sketchup.read_default "SUNPOSITION", "minute", "0"),
				(Sketchup.read_default "SUNPOSITION", "timezone", "1"),
        (Sketchup.read_default "SUNPOSITION", "save_output2", "No")
			]
			list = [
				"",
				"1|2|3|4|5|6|7|8|9|10|11|12",
				"",
				"1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24",
				"",
				"-12|-11|-10|-9|-8|-7|-6|-5|-4|-3|-2|-1|0|1|2|3|4|5|6|7|8|9|10|11|12",
        "Yes|No"
			]
			input2 = UI.inputbox prompts, defaults, list, "Choose a Specific Date"
			return if !input2	#if cancel
			Sketchup.write_default "SUNPOSITION", "year", input2[0].to_i
			Sketchup.write_default "SUNPOSITION", "month",  input2[1].to_i
			Sketchup.write_default "SUNPOSITION", "day", input2[2].to_i
			Sketchup.write_default "SUNPOSITION", "hour",  input2[3].to_i
			Sketchup.write_default "SUNPOSITION", "minute", input2[4].to_i
			Sketchup.write_default "SUNPOSITION", "timezone", input2[5].to_i
      Sketchup.write_default "SUNPOSITION", "save_output2", input2[6].to_s
			y = input2[0].to_f
			m = input2[1].to_f
       if input2[6] == 'Yes'
         hour = 24
         minute = 0
        else 
          hour = input2[3]
          minute = input2[4].to_f
           end
			d = input2[2].to_f + ((hour + (-1 * input2[5].to_f))/24.to_f)  + minute/1440.to_f
	end
	#End Choose a specific date dialog box
	#End Input from User
	if m <= 2
		y -= 1
		m += 12
	end
	a = (y/100).to_int
	b = 2 - a + (a/4).to_int
	jd = (365.25 * (y+4716)).to_int + (30.6001 * (m+1)).to_int + d + b + -1524.5
	# End Julian Day Calculation^^^^
	######################
	#Inputs Passed to 'sunposition' method
	drawsphere = input[4]
	drawlines = input[5]
	sizeofsun = input[6]
save = ''
path_to_save_to = ''
 if input[3] == 'Choose a Specific Date'
 if input2[6] == 'Yes' 
  file_name = 'Posición del sol ' + input2[1].to_s  + '-' + input2[2].to_s + '-' + input2[0].to_s
path = Sketchup.read_default "SUNPOSITION", "file_path", "c:\\"
path_to_save_to = UI.savepanel "Guardar archivo", path, file_name + '.html'
file_ending = path_to_save_to[/(?:.*\.)(.*$)/, 1]
if file_ending == 'html'
  else
path_to_save_to = path_to_save_to + '.html'
end
export_file = File.new(path_to_save_to, "w" )
Sketchup.write_default "SUNPOSITION", "file_path", path_to_save_to
save = 'Yes'
  end
  end
	if save == 'Yes'
    export_file.puts '<title>:Sun Path:' + '(' + input2[1].to_s + '/' + input2[2].to_s + '/' + input2[0].to_s + ')' + '</title>'
  string = <<-FIN
           
           <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
          <head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Untitled 1</title>
<style type="text/css">
.style1 {
	text-align: center;
	font-size: 16pt;
	font-family: Calibri, Verdana, "Trebuchet MS", sans-serif;
	color: #0000FF;
  text-decoration: underline;
}
.style2 {
	text-align: center;
	font-family: Arial, Helvetica, sans-serif;
	color: #000000;
	border: 1px solid #000000;
}
.style4 {
	border: 1px solid #0000FF;
	background-color: #FFFFFF;
}
</style>
</head>
<body style="margin-top: 0; margin-bottom: 0; background-color: #FFFF00">
<html xmlns="http://www.w3.org/1999/xhtml">
</html>


         FIN
export_file.puts string
export_file.puts '<p class="style1"><strong>Date:' + '(' + input2[2].to_s + '/' + input2[1].to_s + '/' + input2[0].to_s + ')'  + '           Latitude: ' + input[0].to_s + '           Longitude: ' + input[1].to_s + '</strong></p>'
export_file.puts '<table style="width: 780px" class="style4" align="center">'

end

  #Draws the Sun every half hour for the next 24 hours
	model = Sketchup.active_model
	model.start_operation "Draw Sun"
	sunnow = -1
	jd -= 0.02083333333333333333333333332
  time = 0
	48.times do
		sunnow += 1
		jd += 0.02083333333333333333333333332
    case sunnow 
      when 0,4,8,12,16,20,24,28,32,36,40,44
           export_file.puts '   	<tr>' if save == 'Yes'
      end
    SUNPOSITION.sunposition(jd,latitude,longitude,belowhoriz,hyp,drawsphere,drawlines,sizeofsun,sunnow,export_file,save,time)
      case sunnow 
      when 3,7,11,15,19,23,27,31,35,39,43,47
           export_file.puts '   	</tr>' if save == 'Yes'
      end
    time += 0.5
  end
	model.commit_operation

	if save == 'Yes'
export_file.puts '   	</tr>'
export_file.puts	"</table>"
export_file.puts "</body>" 
export_file.close
end
	Sketchup.set_status_text "hecho..."
end#Start Sun Position

def SUNPOSITION.sunposition(jd,latitude,longitude,belowhoriz,hyp,drawsphere,drawlines,sizeofsun,sunnow,export_file,save,time)
	# (Meeus Pages 163-164) vvv
	#Time in Julian Centuries
	t = ((jd - 2451545.0)/36525.0)
	#Mean equinox of the date
	l = 280.46645 + 36000.76983*t + 0.0003032*t**2
	#Mean Anomaly of the Sun
	m = 357.52910 + 35999.05030 *t - 0.0001559 *t**2 - 0.00000048*t**3
	#Eccentricity of the Earth's Orbit
	e = 0.016708617 - 0.000042037*t - 0.0000001236*t**2
	# Sun's Equation of the center
	c = (1.914600 - 0.004817 *t - 0.000014 * t**2) * Math.sin(m.to_rad) + (0.019993 - 0.000101*t) * Math.sin(2*m.to_rad) + 0.000290*Math.sin(3*m.to_rad)
	#Sun's True Longitude
	o = l +c
	#Brings 'o' within + or - 360 degrees. (Taking an inverse function of very large numbers can sometimes lead to slight errors in output)
	o = o.divmod(360)[1]
	###############
	#(Meeus Page 164)
	#Sun's Apparant Longitude (The Output of Lambda)
	omega = 125.04 - 1934.136*t
	lambda = o - 0.00569 - 0.00478 * Math.sin(omega.to_rad)
	#Brings 'lambda' within + or - 360 degrees. (Taking an inverse function of very large numbers can sometimes lead to slight errors in output)
	lambda = lambda.divmod(360)[1]
	###############
	#Obliquity of the Ecliptic (Meeus page 147) (numbers switched from degree minute second in book to decimal degree)
	epsilon = (23.4392966666667 - 0.012777777777777778*t - 0.00059/60.to_f * t**2 + 0.00059/60.to_f * t**3) + (0.00256 * Math.cos(omega.to_rad))
	#Sun's Declination (Meeus page 165)
	delta = Math.asin(Math.sin(epsilon.to_rad)*Math.sin(lambda.to_rad)).to_deg
	#Sun's Right Acension (Meeus page 165) (divided by 15 to convert to hours)
	alpha =Math.atan2(((Math.cos(epsilon.to_rad) * Math.sin(lambda.to_rad))),(Math.cos(lambda.to_rad))).to_deg/15
	alpha += 24 if alpha < 0
	#Sidereal Time (Meeus Page 88)
	theta = (280.46061837 + 360.98564736629 * (jd-2451545.0) + 0.000387933*t**2 - ((t**3)/38710000))/15.to_f
	#Brings 'theta' within + or - 360 degrees. (Taking an inverse function of very large numbers can sometimes lead to slight errors in output)
	theta = theta.divmod(360)[1]
	#The Local Hour Angle (Meeus Page 92) (multiplied by 15 to convert to degrees)
	h = (theta - longitude - alpha)*15
	#Brings 'h' within + or - 360 degrees. (Taking an inverse function of very large numbers can sometimes lead to slight errors in output)
	h = h.divmod(360)[1]
	############
	#Local Horizontal Coordinates (Meeus Page 93)
	#Altitude
	altitude = Math.asin(Math.sin(latitude.to_rad)*Math.sin(delta.to_rad) + Math.cos(latitude.to_rad)*Math.cos(delta.to_rad)*Math.cos(h.to_rad)).to_deg
	#Azimuth
	azimuth = Math.atan2((Math.sin(h.to_rad)),((Math.cos(h.to_rad) * Math.sin(latitude.to_rad)) - Math.tan(delta.to_rad) * Math.cos(latitude.to_rad))).to_deg
   if save == 'Yes'
     	#Decides whether or not the user want to save the Sun below the horizon
	sun_on_or_off = 0
	sun_on_or_off = -1000 if belowhoriz == 'yes'
if time >= 12.0
    ampm = 'PM'
  else
    ampm = 'AM'
  end
  if time.to_int == 0
  time +=12
  end
      if time.to_int == time 
      half = '00'
      else
        half = '30'
      end
      if time.to_int > 12
      time -= 12
      else
      end 
  if altitude > sun_on_or_off
    export_file.puts '      <td class="style2">'
    export_file.puts 'Horario:'  
    export_file.puts time.to_int.to_s + ':' + half + ampm
    export_file.puts '<br>'
    export_file.puts 'Altitud:'
    export_file.puts (((altitude*1000.0).to_int)/1000.0).to_s
    export_file.puts '<br>'
    export_file.puts 'Azimuth:'
    export_file.puts (((azimuth*1000.0).to_int)/1000.0).to_s
    export_file.puts '      </td>'
  end
  if belowhoriz == 'no' and altitude < 0
  export_file.puts '      <td class="style2">'
  export_file.puts 'Horario:'
  export_file.puts time.to_int.to_s + ':' + half + ampm
  export_file.puts '<br>'
  export_file.puts '--------' 
  export_file.puts '<br>'
  export_file.puts '--------' 
  export_file.puts '      </td>'
  end
end
  ############
	#Decides whether or not the user want to draw the Sun below the horizon
	sun_on_or_off = 0
	sun_on_or_off = -1000 if belowhoriz == 'yes'
	if altitude > sun_on_or_off
		model = Sketchup.active_model
		entities = model.active_entities
		#get north position
		model = Sketchup.active_model
		n = model.shadow_info["NorthAngle"]
		#Altitude and Azimuth to XYZ
		#Rotate XYZ
		z = hyp* Math.sin(altitude.to_rad)
		adj = z/Math.tan(altitude.to_rad)
		y = adj*Math.sin((azimuth + 270 + n).to_rad)
		x = y/Math.tan((azimuth + 270 + n).to_rad)
		#################################
		#Creates the Sun
		centerpoint = Geom::Point3d.new((x * -1),(y),(z))
		vector = Geom::Vector3d.new 0,1,0
		vector2 = vector.normalize!
		vector3 = Geom::Vector3d.new 1,0,0
		vector4 = vector3.normalize!
		#Draws the sun bigger as it gets farther away from the origin.
		sunsize = sizeofsun.to_i/5000 * 50	
		#Group Each Sun
		group = Sketchup.active_model.entities.add_group
		if sunnow == 0
			circle = group.entities.add_circle centerpoint, vector2, sunsize * 2
			circle2 = group.entities.add_circle centerpoint, vector4, sunsize * 2
		else
			circle = group.entities.add_circle centerpoint, vector2, sunsize
			circle2 = group.entities.add_circle centerpoint, vector4, sunsize
		end
		#Decides whether or not to draw construction lines to origin
		entities.add_line [0,0,0], centerpoint if drawlines == 'Yes'
		return if drawsphere.include? "line"
		face = group.entities.add_face circle
		face2 = group.entities.add_face circle2
		#Paints the sun yellow if it is above the horizon and if it is at a moment besides now
		sun_color = "yellow"
		#Paints the sun orange if the sun is above the horizon and it is the sun right now.
		sun_color = "orange" if altitude >0 and sunnow == 0
		#Paints the sun black if it is below the horizon and if it is at a moment besides now
		sun_color = "black" if altitude <0
		#Paints the sun purple if the sun is below the horizon and it is the sun right now.
		sun_color = "purple" if altitude <0 and sunnow == 0
		#Colors first faces
		face.material = sun_color
		face.back_material= sun_color
		#Colors second faces
		face2.material = sun_color
		face2.back_material= sun_color
		#Decides whether or not the draw the sun as a sphere
		face.followme circle2 if drawsphere.include? "sphere"
		#Finish create sun
		##################################
	end #End Check if Altitude is above or below horizon	
end#Sunposition

def SUNPOSITION.sunpositionhelp
  UI.openURL "http://www.cerebralmeltdown.com/projects/sunplugin/default.htm"
end

def SUNPOSITION.get_north
	model = Sketchup.active_model
	prompts = ["Angulo del norte", "Mostrar el norte"]
	defaults = [model.shadow_info["NorthAngle"].to_s, model.shadow_info["DisplayNorth"]]
	list = [ "", "verdadero|falso"]
	input = UI.inputbox prompts, defaults, list, "Opciones Norte"
	return if !input	#if canceled
	if !(input[0] =~ /(\d+).*(\d+)/)	#if not a number
		UI.messagebox "Angulo no es un número"
		return
	end
	model.shadow_info["NorthAngle"] = input[0].to_fl
	model.shadow_info["DisplayNorth"] = eval(input[1])
end

end #END MODULE
######################################
##### menu loading
######################################
require "SUNPOSITION"

 
if !file_loaded?(filename)
	# get the SketchUp plugins menu
	draw_menu = UI.menu("Plugins")
  submenu = draw_menu.add_submenu("Sun Position V1.2.1")
  if draw_menu
		submenu.add_item("Trazar soles") {SUNPOSITION.startsunposition}
		submenu.add_item("Obtener/mostrar el norte") {SUNPOSITION.get_north}
    submenu.add_separator
		submenu.add_item("Cómo uso este plugin? (en inglés)") {SUNPOSITION.sunpositionhelp}
	end
	# Let Ruby know we have loaded this file
	file_loaded(filename)
end
