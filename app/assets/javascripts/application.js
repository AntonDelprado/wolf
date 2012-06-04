// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require_tree .

$(document).ready(function() {
	$('#skill-filter').change(skill_filter_change)
	synergy_classes = ["warrior", "rogue", "channeller", "mechanist", "trickster", "battle-mage", "necromancer", "lore", "no-synergy"]
});

function skill_filter_change()
{
	if ($(this).val() == "All")
	{
		for (var i=0; i<synergy_classes.length; i+=1)
			$('.' + synergy_classes[i]).css('display', 'block');
		// $('.warrior').css('display', 'block');
	}
	else
	{
		for (var i=0; i<synergy_classes.length; i+=1)
			$('.' + synergy_classes[i]).css('display', 'none');

		switch ($(this).val())
		{
			case "Warrior": $('.warrior').css('display', 'block'); break;
			case "Rogue": $('.rogue').css('display', 'block'); break;
			case "Channeller": $('.channeller').css('display', 'block'); break;
			case "Mechanist": $('.mechanist').css('display', 'block'); break;
			case "Trickster": $('.trickster').css('display', 'block'); break;
			case "Battle Mage": $('.battle-mage').css('display', 'block'); break;
			case "Necromancer": $('.necromancer').css('display', 'block'); break;
			case "Lore": $('.lore').css('display', 'block'); break;
			case "None": $('.no-synergy').css('display', 'block'); break;
		}
	}

}
