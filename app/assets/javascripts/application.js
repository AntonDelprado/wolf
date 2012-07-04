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
	$('#skill-filter').change(function () { skill_filter_change('skill-', $(this).val()); });
	$('#skill_filter').change(function () { skill_filter_change('add-', $(this).val()); });
	$('#statsBase').change(stats_change);
	synergy_classes = ["warrior", "rogue", "channeller", "mechanist", "trickster", "battle-mage", "necromancer", "lore", "no-synergy"]
	stats_change();

	var activeTab = $('[href=' + location.hash + ']');
	activeTab && activeTab.tab('show');
	
	$('.add_ability').each(function () {
		if ($(this).attr('id').indexOf("Follower") != -1)
			$(this).change(function () { follower_selected($(this)) });
	});

	$('.skill-popover').popover({
		html : true,
		trigger : 'manual'
	}).mouseenter(function () {
		$(this).popover('show');
	}).mouseleave(function () {
		$(this).popover('hide');
	}).click(function () {
		$(this).popover('toggle');
	});

	recalculate_xp();
});

function roll(value, type)
{
	var result = 0;
	while (type < 4)
	{
		value -= 2;
		type += 2;
	}
	while (type > 12)
	{
		value += 2;
		type -= 2;
	}

	for (var i=0; i<value; i+=1)
		if (Math.random()*type >= 3)
			result += 1;

	alert("Result: " + result);
}

function total_time(size, rate)
{
	var seconds;
	if (rate >= 0)
		seconds = 10*size/(1+rate);
	else
		seconds = 10 * size * Math.pow(2,-rate);
	
	if (seconds < 60)
		alert("Time taken until full is " + seconds + "s")
	else if (seconds < 3600)
		alert("Time taken until full is " + (parseInt(seconds/6)/10.0) + " min");
	else
		alert("Time taken until full is " + (parseInt(seconds/360)/10.0) + " hrs")
}

function skill_filter_change(prefix, value)
{
	if (value == "All")
	{
		for (var i=0; i<synergy_classes.length; i+=1)
			$('.' + prefix + synergy_classes[i]).css('display', 'block');
	}
	else
	{
		for (var i=0; i<synergy_classes.length; i+=1)
			$('.' + prefix + synergy_classes[i]).css('display', 'none');

		switch (value)
		{
			case "Warrior": $('.' + prefix + 'warrior').css('display', 'block'); break;
			case "Rogue": $('.' + prefix + 'rogue').css('display', 'block'); break;
			case "Channeller": $('.' + prefix + 'channeller').css('display', 'block'); break;
			case "Mechanist": $('.' + prefix + 'mechanist').css('display', 'block'); break;
			case "Trickster": $('.' + prefix + 'trickster').css('display', 'block'); break;
			case "Battle Mage": $('.' + prefix + 'battle-mage').css('display', 'block'); break;
			case "Necromancer": $('.' + prefix + 'necromancer').css('display', 'block'); break;
			case "Lore": $('.' + prefix + 'lore').css('display', 'block'); break;
			case "None": $('.' + prefix + 'no-synergy').css('display', 'block'); break;
		}
	}
}

function follower_selected (this_obj)
{
	if (this_obj.is(':checked'))
	{
		$('.add_ability').each (function () {
			if ($(this).attr('id').indexOf("Follower") != -1)
				$(this).attr('checked', false);
		});

		this_obj.attr('checked', true);
	}
}

function stats_change()
{
	for (var i=0; i<$('#base_stats option').length; i+=1)
		if ($('#base_stats').val() == i)
			$('#raw_stats'+i).css('display', 'block');
		else
			$('#raw_stats'+i).css('display', 'none')
}

function remove_selected(skill_name)
{
	box = $('#remove_'+skill_name.replace(/[ ]/g, '_'))

	if (box.length == 0)
		return;

	if (box.is(':checked'))
	{
		for (var skill in skill_requires)
			if (skill_requires[skill] == skill_name)
			{
				$('#remove_'+skill.replace(/[ ]/g, '_')).attr('checked', true);
				remove_selected(skill)
			}
	}
	else
	{
		skill = skill_requires[skill_name];
		if (skill)
		{
			$('#remove_'+skill.replace(/[ ]/g, '_')).attr('checked', false);
			remove_selected(skill)
		}
	}
}

function add_selected(skill_name)
{
	box = $('#add_'+skill_name.replace(/[ ]/g, '_'))

	if (box.length == 0)
		return;

	if (box.is(':checked'))
	{
		skill = skill_requires[skill_name];
		if (skill)
		{
			$('#add_'+skill.replace(/[ ]/g, '_')).attr('checked', true);
			add_selected(skill)
		}
	}
	else
	{
		for (var skill in skill_requires)
			if (skill_requires[skill] == skill_name)
			{
				$('#add_'+skill.replace(/[ ]/g, '_')).attr('checked', false);
				add_selected(skill)
			}
	}
}


function show_skill_levels()
{
	$('.skill-level').css('display', 'none');
	$('.skill-level-select').css('display', 'block');
	$('.power').css('color', '#ddd');
	$('.disable-button').attr('disabled', true);
	$('.disable-button').click(function () { return false; });
}

function name_to_option(skill_name)
{
	return $('#level_' + skill_name.replace(/[ ]/g, '_'))
}

function option_to_name(option_obj)
{
	return option_obj.attr('id').substr(6).replace(/_/g, ' ')
}

function raise_level(skill_name, level)
{
	if (name_to_option(skill_name).val() < level)
	{
		name_to_option(skill_name).val(level)
		if (skill_requires[skill_name])
			raise_level(skill_requires[skill_name], level+1)
	}
}

function lower_level(skill_name, level)
{
	if (name_to_option(skill_name).val() > level)
	{
		name_to_option(skill_name).val(level)
		for (var requires in skill_requires)
		{
			if (skill_requires[requires] == skill_name)
				lower_level(requires, level-1);
		}
	}
}

function update_required(skill_name)
{
	level = parseInt(name_to_option(skill_name).val());

	if (skill_requires[skill_name])
		raise_level(skill_requires[skill_name], level+1);

	for (var requires in skill_requires)
	{
		if (skill_requires[requires] == skill_name)
			lower_level(requires, level-1);
	}
}

function recalculate_xp()
{
	var xp_total = 0

	$(".skill-level-option").each(function () {
		xp_total += skill_costs[option_to_name($(this))] * $(this).val();
	});

	$("#xp").html(xp_total)
}