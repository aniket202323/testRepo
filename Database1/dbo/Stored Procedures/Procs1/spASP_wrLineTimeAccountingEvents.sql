CREATE procedure [dbo].[spASP_wrLineTimeAccountingEvents]
@Units nVarChar(1000)
AS
Declare @UnitsClause as nvarchar(300)
Declare @SQL as varchar(4000)
If @Units is not null 
 	 Set @UnitsClause = ' and ec.PU_Id in (' + @Units + ') '
else
 	 Set @UnitsClause = ''
SET @SQL = 'Select Id = -2, Description = ''Non-Productive Time'' Union ' +
 	  	  	 'select Id=0,Description=''Crew Schedule'' Union ' + 
 	  	  	 'Select distinct Id = ec.et_id, Description =  coalesce(es.event_subtype_desc, et.et_desc) ' +
 	  	  	  	  	 'From Event_Configuration ec '+
 	  	  	  	  	 'Join Event_Types et on et.et_id = ec.et_id ' +
 	  	  	  	  	 'Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id ' +
 	  	  	  	  	 'Where ec.et_id not in (0,5,6,7,8,9,10,11,14,16,17,18,20,21,22) ' +
 	  	  	  	  	 @UnitsClause + ' Union ' +
 	  	  	  'Select distinct Id=es.Event_Subtype_Id + 1400, Description = es.Event_Subtype_Desc ' +
 	  	  	  	  	 'From Event_Subtypes es ' +
 	  	  	  	  	 'Inner Join Event_Configuration ec ' +
 	  	  	  	  	 'On ec.Event_Subtype_Id = es.Event_Subtype_Id Where ec.ET_Id = 14 ' +
 	  	  	  	 + @UnitsClause + ' Union ' +
 	  	  	   'Select distinct Id=a.var_id + 11000, Description=ec.var_desc ' +
 	  	  	  	  	 'from variables ec inner join alarm_template_var_data a on a.var_id = ec.var_id ' +
 	  	  	  	  	 ' where 1=1 ' + @UnitsClause + ' ORDER BY Id'
Execute (@SQL)
