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
	$('#base_stats').change(stats_change);
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

	$('.hp-popover').popover({
		html : true,
		trigger : 'manual',
		placement : 'top'
	}).click(function () {
		var index = parseInt($(this).attr('index'));
		var field;
		$(this).popover('toggle');
		field = $('.hp-field[index='+index+']');
		if (field.length)
		{
			field.focus();
			field.focusout(function () {
				$('.hp-popover[index='+index+']').popover('hide');
			});
		}
	});

	$('.mp-popover').popover({
		html : true,
		trigger : 'manual',
		placement : 'top'
	}).click(function () {
		var index = parseInt($(this).attr('index'));
		var field;
		$(this).popover('toggle');
		field = $('.mp-field[index='+index+']');
		if (field.length)
		{
			field.focus();
			field.focusout(function () {
				$('.mp-popover[index='+index+']').popover('hide');
			});
		}
	});

	recalculate_xp();

	skill_levels_run = 0
});

function roll(value, type)
{
	var result = 0, result_type;
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
		if (0) // First roll type is >=4; second is >=4 is 1, >=8 is 2, >=12 is 3
		{
			if (Math.random()*type >= 3)
				result += 1;
		}
		else
			result += Math.floor((Math.random()*type+1)/4);

	if (result <= 0)
		alert("Result: " + result + ' (Critical Failure)');
	else if (result <= 2)
		alert("Result: " + result + ' (Failure)');
	else if (result <= 5)
		alert("Result: " + result + ' (Basic Pass)');
	else if (result <= 10)
		alert("Result: " + result + ' (Pass)');
	else if (result <= 17)
		alert("Result: " + result + ' (Skillful Pass)');
	else if (result <= 26)
		alert("Result: " + result + ' (Prodigious Pass)');
	else
		alert("Result: " + result + ' (Epic Pass)');
}

function add(elem_id, amount)
{
	var elem = $('#' + elem_id)

	elem.html(parseInt(elem.html())+parseInt(amount));
	if (parseInt(elem.attr('max')) < parseInt(elem.html()))
		elem.css('font-weight', 'bold');
	else
		elem.css('font-weight', 'normal');
}

function update_hp(index)
{
	var field = $('.hp-field[index='+index+']'), contents = parseInt(field.val());
	field.val("");
	$('.hp-popover[index='+index+']').popover('hide');

	if (isNaN(contents))
		alert("Warning: Not a number!");
	else
		add('hp_'+index, contents);
}

function update_mp(index)
{
	var field = $('.mp-field[index='+index+']'), contents = parseInt(field.val());
	field.val("");
	$('.mp-popover[index='+index+']').popover('hide');

	if (isNaN(contents))
		alert("Warning: Not a number!");
	else
		add('mp_'+index, contents);
}

function row_next(index)
{
	var elem = $('.combat-row[index=' + index + ']'), next = elem.next();

	if (next.length)
	{
		next.after(elem);
	}
	else
	{
		elem.parent().children().first().before(elem);
	}

	update_current_character();
}

function row_prev(index)
{
	var elem = $('.combat-row[index='+index+']'), prev = elem.prev();
	if (prev.length)
	{
		prev.before(elem);
	}
	else
	{
		elem.parent().children().last().after(elem);
	}

	update_current_character();
}

function update_current_character()
{
	var index = parseInt($('.combat-row').first().attr('index'));

	$('#current_character').children().each(function () {
		var this_index = parseInt($(this).attr('index'));
		$(this).css('display', index == this_index ? 'inline' : 'none');
	})
}

function next_character()
{
	$('.combat-row').last().after($('.combat-row').first());
	update_current_character();

	var char_index = parseInt($('.combat-row').first().attr('index'));
	for (var i=0; i<buffs.length; i+=1)
	{
		var buff = buffs[i];
		if (buff['owner'] == char_index)
		{
			buff['duration'] -= 1;
			if (buff['duration'] <= 0)
			{
				$('.buff-row[index='+buff['index']+']').remove();

				buffs.splice(i, 1);
				i -= 1; /* Ensure an element is not skipped. */
			}
			else
			{
				$('.buff-duration[index='+buff['index']+']').each(function () {
					$(this).html(buff['duration']);
				});
			}
		}
	}
}

function select_character(index)
{
	$('.combat-row').each(function () {
		var this_index = parseInt($(this).attr('index'));
		$(this).css('background-color', index == this_index ? '#eef' : '#fff');
	});

	$('#current_character').children().each(function () {
		var this_index = parseInt($(this).attr('index'));
		$(this).css('display', index == this_index ? 'inline' : 'none');
	});
}

function show_targets()
{
	if ($('#buff_target').val() == 'Custom')
		$('#buff-targets').css('display', 'inline');
	else
		$('#buff-targets').css('display', 'none');
}

function new_buff()
{
	var owner_index = parseInt($('.combat-row').first().attr('index')), target = $('#buff_target').val();
	var buff = {
		'owner' : owner_index,
		'name' : $('#buff_name').val(),
		'duration' : parseInt($('#buff_duration').val()),
		'characters' : [],
		'index' : buff_index,
		'effect' : $('#buff_effect').val(),
		'size' : $('#buff_size').val(),
	};

	if (target == 'Everyone')
	{
		var i, total = character_names.length;
		for (var i=0; i<total; i+=1)
			buff['characters'].push(i);
	}
	else if (target == 'Friends')
		alert('Not Implemented');
	else if (target == 'Foes')
		alert('Not Implemented');
	else /* Custom */
	{
		$('.buff-character:checked').each(function () {
			buff['characters'].push(parseInt($(this).attr('index')));
		});
	}

	buffs.push(buff);

	var i;
	for (i=0; i<buff['characters'].length; i+=1)
	{
		var index = buff['characters'][i];
		var table_row = '<tr class="buff-row" index="' + buff_index + '">';
		table_row += '<td>' + buff['name'] + '</td>';
		table_row += '<td>' + character_names[owner_index] + '</td>';
		table_row += '<td class="buff-duration" index="' + buff_index + '">' + buff['duration'] + '</td>';
		table_row += '<td>' + buff['effect'] + ': ' + buff['size'] + '</td></tr>';

		$('#buffs_' + index).append(table_row);
	}

	buff_index += 1;
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
	skill_levels_run += 1
	$('.skill-level').css('display', 'none');
	$('.skill-level-select').css('display', 'block');
	$('.power').css('color', '#ddd');
	$('.disable-button').attr('disabled', true);
	$('.disable-button').click(function () { return false; });

	$('#skill-levels').html('')
	$('#skill-levels').append('<i class="icon-ok icon-white"></i> Save Changes')

	$('#skill-levels').click(submit_skill_levels);
}

function submit_skill_levels()
{
	$('#form-skill-levels').submit();
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
