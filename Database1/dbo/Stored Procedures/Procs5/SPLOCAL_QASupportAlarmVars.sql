

/*
execute SPLOCAL_QASupportAlarmVars 4,'list_corrections'
execute SPLOCAL_QASupportAlarmVars 4,'list'
execute SPLOCAL_QASupportAlarmVars 4,'repair'

*/
CREATE PROCEDURE SPLOCAL_QASupportAlarmVars
--**********************************************************************
-- François Bergeron   (819)373-3332 #35  (STI)
-- DESCRIPTION:	       SP that verify if the extended info is adequate
-- INPUTS:	       Production line id
--                     repair/list/list_corrections
--**********************************************************************
@PL_id integer,     --Production line id --test with 7
@UL      varchar(25)  --Input list for listing the bad extended info and 
                      --repair if you wish to repair
AS

DECLARE
@pl_desc  varchar(30),
@pu_desc varchar(30),
@pu_id 	integer,
@CAID   integer, 
@CADE   varchar(100),
@str    varchar(1000)

--Line stuff
select @pl_desc=pl_desc from prod_lines where pl_id=@pl_id

--Find the unit
select @pu_desc=pu_desc,@pu_id=pu_id from prod_units 
where pu_desc=@pl_desc+' Quality'



Create table #ListC(
Update_str   varchar(1000))

create table #Variables_AL(
ToBeCorrected varchar(5),
alarm_group   varchar(25),
alarm_id integer,
alarm_desc varchar(100),
alarm_extinfo varchar(25),
source_group varchar(25),
source_var_id integer,
source_var_desc varchar(100),
Corrected_group  varchar(30),
Corrected_var_id   integer,
Corrected_var_desc  varchar(100))


insert into #Variables_AL(alarm_group,alarm_id,alarm_desc,alarm_extinfo,
                          source_group,source_var_id,source_var_desc)

select pug.pug_desc,v.var_id,v.var_desc,v.extended_info,
       pug1.pug_desc,v1.var_id,v1.var_desc
       from variables v 
       join pu_groups pug on v.pug_id=pug.pug_id 
       join variables v1 on v1.var_id=convert(integer,v.extended_info)
       join pu_groups pug1 on pug1.pug_id=v1.pug_id 
       where v.pu_id=@pu_id and isnumeric(v.extended_info)=1


update #Variables_AL set ToBeCorrected='NO' where source_var_desc= 
left(Alarm_desc,len(alarm_desc)-3)


update #Variables_AL set ToBeCorrected='YES' where source_var_desc <> 
left(Alarm_desc,len(alarm_desc)-3)


DECLARE Correction_cursor CURSOR FOR
SELECT alarm_id,Alarm_desc from #Variables_AL where ToBeCorrected='YES'

OPEN Correction_cursor


FETCH NEXT FROM Correction_cursor
INTO @CAID, @CADE

WHILE @@FETCH_STATUS = 0
BEGIN

if (select count(var_id) from variables where var_desc = left(@CADE,len(@CADE)-3)and pu_id=@pu_id)>1
begin
   PRINT 'Alarm Var_desc ' + @CADE + ', Alarm Var_id ' + convert(varchar(25),@CAID) + ' Has multiple corresponding var_desc'
   return
end

else
begin
   update #Variables_AL set 
   Corrected_var_id = (select var_id from variables where var_desc = left(@CADE,len(@CADE)-3)and pu_id=@pu_id) where alarm_id=@CAID

   update #Variables_AL set 
   Corrected_var_desc = (select var_desc from variables where var_desc = left(@CADE,len(@CADE)-3)and pu_id=@pu_id) where alarm_id=@CAID

   set @str='update variables set extended_info = ' + 
   (select convert(varchar(10),corrected_var_id) from  #Variables_AL where alarm_id=@CAID) +
   ' Where var_id = ' + convert(varchar(10),@CAID)

   insert into #ListC(update_str)
   values (@str)

   if @UL= 'repair' and @str is not null
      exec(@str)
end

   FETCH NEXT FROM Correction_cursor
   INTO @CAID, @CADE
END

CLOSE Correction_cursor
DEALLOCATE Correction_cursor







if @UL = 'list'
select * from #Variables_AL order by tobecorrected
--select alarm_desc,source_var_desc, corrected_var_desc, corrected_var_id from  #Variables_AL


if @UL='list_corrections'
select * from #ListC where update_str is not null



drop table #Variables_AL




