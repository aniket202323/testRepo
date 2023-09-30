



/*
execute spLocal_SupportFixAlarmVars <Line ID>,'list_corrections' -- what will it fix
execute spLocal_SupportFixAlarmVars <Line ID>,'list' -- show all variables for this line, and if they are okay or not
execute spLocal_SupportFixAlarmVars <Line ID>,'repair' -- Fix the variables
execute spLocal_SupportFixAlarmVars <Line ID>,'no_match' -- Show the ones it does not know how to fix
*/
Create  PROCEDURE spLocal_SupportFixAlarmVars
--**********************************************************************
-- Ketki Pophali (Capgemini)
-- Modification:	FO-03488: App version entry in stored procedures using Appversions table
-- VERSION:	       1.2
-- DATE: 	       27-May-2019
-------------------------------------------------------------------------------------------------------
-- Namrata Kumar (TCS)
-- Modification:	CR# FO-02451 (Changed alarm_extinfo to varchar(255) from varchar(25))
-- VERSION:	       1.1
-- DATE: 	       8-Mar-2016
--**********************************************************************
-- Ugo Lapierre   (819)373-3332 #27  (STI)
-- Modification:	Does not take care of obsolete variables (z_obs_XXXXX)
-- VERSION:	       2.1
-- DATE: 	       9-Apr-2004
-- INPUTS:	       Production line id
--                     repair/list/list_corrections/no_match
--**********************************************************************
-- François Bergeron   (819)373-3332 #35  (STI)
-- DESCRIPTION:	       SP that verify if the extended info is adequate
-- VERSION:	       2.0
-- DATE: 	       26-mar-2004
-- INPUTS:	       Production line id
--                     repair/list/list_corrections/no_match
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
@FAID   integer,
@FADESC varchar(50), 
@FADESCi varchar(50),
@SAID   integer,
@SDESC  varchar(50),
@SGRP   varchar(30),
@EIFO   varchar(30),
@CADE   varchar(100),
@str    varchar(1000),
@ount   integer,
@count  integer,
@BlanksPOS integer,
@BlanksPOSP integer,
@BlanksPOSP1 integer,
@pass        integer,
@var_part   varchar(30),
@EXECSTRING varchar(5000),
@EXECSTRING2 varchar(5000),
@STRF	    VARCHAR(5000)


--Line stuff
select @pl_desc=pl_desc from prod_lines_base WITH(NOLOCK) where pl_id=@pl_id

--Find the unit
select @pu_desc=pu_desc,@pu_id=pu_id from prod_units_base WITH(NOLOCK) 
where pu_desc=@pl_desc+' Quality'



Create table #ListC(
Update_str   varchar(1000))

create table #TEMPvariables(
var_id integer,
var_desc varchar(50))

create table #VAR_PART(
var_part varchar(50),
BlanksPOSP integer)

create table #TEMPvariables_AL(
ToBeCorrected 		varchar(25),
alarm_group   		varchar(25),
alarm_id 		integer,
alarm_desc 		varchar(100),
alarm_extinfo 		varchar(255),
source_group 		varchar(25),
source_var_id 		integer,
source_var_desc 	varchar(100),
Corrected_group 	varchar(30),
Corrected_extended_info integer,
Corrected_var_desc  	varchar(100),
varcount            	integer)



insert into #TEMPvariables_AL(alarm_group,alarm_id,alarm_desc,alarm_extinfo
                          ,source_group,source_var_id,source_var_desc)

select pug.pug_desc,v.var_id,v.var_desc,v.extended_info,
       pug1.pug_desc,v1.var_id,v1.var_desc

       from variables_base v WITH(NOLOCK)
       join pu_groups pug WITH(NOLOCK) on v.pug_id=pug.pug_id and pug.pug_desc in ('QV Alarms','QA Alarms')
       full outer join variables_base v1 WITH(NOLOCK) on v1.var_desc=left(v.var_desc,len(v.var_desc)-3)and v1.pu_id=@pu_id
       full outer join pu_groups pug1 WITH(NOLOCK) on pug1.pug_id=v1.pug_id 
       where v.pu_id=@pu_id and right(v.var_desc,3)='_AL' and v.var_desc not like 'z_obs%' order by v.var_id




DECLARE FindVAR_cursor CURSOR FOR
SELECT alarm_id, alarm_desc,source_var_id,alarm_extinfo, source_var_desc,source_group 
from #TEMPvariables_AL

OPEN FindVAR_cursor

FETCH NEXT FROM FindVAR_cursor
INTO @FAID,@FADESC,@SAID,@EIFO,@SDESC,@SGRP


WHILE @@FETCH_STATUS = 0
BEGIN

   delete #var_part
   select @count=1

   if  @SAID is null --NO MATCH FOR _al
   begin

      if @EIFO is null or @EIFO='' --IF EXTENDED_INFO OF _AL IS NULL
      begin --SPECIAL TREATMENT--THE SOURCE VAR_DESC DOES NOT CORRESPOND TO _al

         set @BlanksPOS=0
         set @BlanksPOSP=0
         select @EXECSTRING='select var_id from variables where pu_id=' + convert(varchar(4),@pu_id)+ ' and '
         select @EXECSTRING2='select count(var_id) from variables where pu_id=' + convert(varchar(4),@pu_id)+ ' and '

         set @FADESCi=left(@Fadesc,len(@fadesc)-3)

         WHILE charindex(' ',@FADESCi,@BlanksPOS+1)>0
         BEGIN    

           select @BlanksPOS=charindex(' ',@FADESCi,@BlanksPOS+1)
           
           if @BlanksPOSP is null
           begin
 
             insert into #var_part(var_part,BlanksPOSP)
              select substring(@FADESCi,0,@BlanksPOS-2),0              

           end    
           else
           begin

              insert into #var_part(var_part,BlanksPOSP)
              select substring(@FADESCi,@BlanksPOSP+1,@BlanksPOS-@BlanksPOSP-1),@BlanksPOSP
              
           end

           select @count=@count+1
           select @BlanksPOSP=charindex(' ',@FADESCi,@BlanksPOS)

        
        
        END

        insert into #var_part(var_part,BlanksPOSP)
        select substring(@FADESCi,@BlanksPOSP+1,len(@fadesci)-@BlanksPOSP),@BlanksPOSP
        
        set @ount=1
        set @pass=0
        
        DECLARE Correction_cursor CURSOR FOR
        SELECT var_part,blanksposP from #var_part
        OPEN Correction_cursor


        FETCH NEXT FROM Correction_cursor        INTO @var_part, @blanksposP1
 
        WHILE @@FETCH_STATUS = 0
        BEGIN

           if ltrim(@var_part) <>''
           begin
              if @pass=0
              begin

                 if len(@var_part)=1 and isnumeric(@var_part)=1
                 begin
                    select @EXECSTRING=@EXECSTRING + ' right(var_desc,3) <>''_al''' + ' and (charindex('' ' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ''',var_desc,0)>0)'
                    select @EXECSTRING2=@EXECSTRING2 + ' right(var_desc,3) <>''_al''' + ' and (charindex('' ' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ''',var_desc,0)>0)'

                 end
                 else
                 begin
                    if len(@var_part)=1 and isnumeric(@var_part)=0
                    begin
                       select @EXECSTRING=@EXECSTRING + ' right(var_desc,3) <>''_al''' + ' and charindex('' ' + @var_part + ' '',var_desc,0) >0'
                       select @EXECSTRING2=@EXECSTRING2 + ' right(var_desc,3) <>''_al''' + ' and charindex('' ' + @var_part + ' '',var_desc,0) >0'
                    end
                    else
                    begin
                       select @EXECSTRING=@EXECSTRING + ' right(var_desc,3) <>''_al''' + ' and (charindex(''' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ''',var_desc,0) >0 or charindex('' ' + @var_part + ' '',var_desc,0) >0)'
		       select @EXECSTRING2=@EXECSTRING2 + ' right(var_desc,3) <>''_al''' + ' and (charindex(''' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ''',var_desc,0) >0 or charindex('' ' + @var_part + ' '',var_desc,0) >0)'
                    end
                 end  
              end
              else
              begin

                 if @ount=(select count(var_part) from #VAR_PART)
                 begin    
                    if len(@var_part)=1 and isnumeric(@var_part)=1
                    begin
                       select @EXECSTRING=@EXECSTRING+' and ' + '(charindex('' ' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ''',var_desc,0) >0)' + ' and len(var_desc)<=len(''' + @FADESCi +''')'
                       select @EXECSTRING2=@EXECSTRING2+' and ' + '(charindex('' ' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ''',var_desc,0) >0)' + ' and len(var_desc)<=len(''' + @FADESCi +''')'
                    end
                    else
                    begin    
                       if len(@var_part)=1 and isnumeric(@var_part)=0
                       begin
                          select @EXECSTRING=@EXECSTRING+' and ' + 'charindex('' ' + @var_part + ' '',var_desc,0) >0' + ' and len(var_desc)<=len(''' + @FADESCi +''')'
                          select @EXECSTRING2=@EXECSTRING2+' and ' + 'charindex('' ' + @var_part + ' '',var_desc,0) >0' + ' and len(var_desc)<=len(''' + @FADESCi +''')'
                       end
                       else
                       begin
                          select @EXECSTRING=@EXECSTRING+' and ' + '(charindex('' ' + @var_part + ''',var_desc,0) >0 or charindex(''' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ' '',var_desc,0) >0)' + ' and len(var_desc)<=len(''' + @FADESCi +''')'
                          select @EXECSTRING2=@EXECSTRING2+' and ' + '(charindex('' ' + @var_part + ''',var_desc,0) >0 or charindex(''' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ' '',var_desc,0) >0)' + ' and len(var_desc)<=len(''' + @FADESCi +''')'
                       end
                    end
                 end
                 else
                 begin
                    if len(@var_part)=1 and isnumeric(@var_part)=1
                    begin
                       select @EXECSTRING=@EXECSTRING+' and ' + '(charindex('' ' + @var_part + ' '',var_desc,0)>0 or charindex('' ' + @var_part + ''',var_desc,0) >0)'
                       select @EXECSTRING2=@EXECSTRING2+' and ' + '(charindex('' ' + @var_part + ' '',var_desc,0)>0 or charindex('' ' + @var_part + ''',var_desc,0) >0)'
                    end
                    else
                    begin
                       if len(@var_part)=1 and isnumeric(@var_part)=0
                       begin
                          select @EXECSTRING=@EXECSTRING+' and ' + 'charindex('' ' + @var_part + ' '',var_desc,0) >0'
                          select @EXECSTRING2=@EXECSTRING2+' and ' + 'charindex('' ' + @var_part + ' '',var_desc,0) >0'

                       end
                       else
                       begin
                          select @EXECSTRING=@EXECSTRING+' and ' + '(charindex('' ' + @var_part + ''',var_desc,0) >0 or charindex(''' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ' '',var_desc,0) >0)'
                          select @EXECSTRING2=@EXECSTRING2+' and ' + '(charindex('' ' + @var_part + ''',var_desc,0) >0 or charindex(''' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ' '',var_desc,0) >0)'
 
                      end
                    end      
                 end
              end
              set @pass=1
           end
           set @ount=@ount+1
        FETCH NEXT FROM Correction_cursor
        INTO @var_part, @blanksposP1
        END
        CLOSE Correction_cursor
        DEALLOCATE Correction_cursor
        
        select @STRF= 'update #TEMPvariables_AL set varcount=(' + @EXECSTRING2 +') where alarm_id=' + convert(varchar(10),@FAID)
	exec(@STRF)
        set @STRF=''
        select @STRF= 'update #TEMPvariables_AL set Corrected_extended_info=(' + @EXECSTRING +') where alarm_id=' + convert(varchar(10),@FAID) + ' and varcount=1' 
           exec(@STRF)

        if (select corrected_extended_info from  #TEMPvariables_AL where alarm_id=@FAID) is not null
	update #TEMPvariables_AL set tobecorrected='YES' where alarm_id=@FAID
        else
	update #TEMPvariables_AL set tobecorrected='MISSMATCH' where alarm_id=@FAID
        

/*debug
--print left(@STRF,256)
--if len(@STRF) >256
--print right(@STRF,len(@STRF)-256)
--exec('if (' + @EXECSTRING +') is null begin exec(' + @STRF +') end)'
*/     
     end
     else  --IF EXTENDED_INFO IS NOT NULL AND SOURCE ID IS NULL --NO MATCH BASED ON THE NAME
     begin  --VERIFY IF THE EXTENDED_INFO MATCHES A GOOD CORRESPONDING VARIABLE












         set @BlanksPOS=0
         set @BlanksPOSP=0
         select @EXECSTRING='select var_id from variables_base WITH(NOLOCK) where pu_id=' + convert(varchar(4),@pu_id)+ ' and '
         select @EXECSTRING2='select count(var_id) from variables_base WITH(NOLOCK) where pu_id=' + convert(varchar(4),@pu_id)+ ' and '

         set @FADESCi=left(@Fadesc,len(@fadesc)-3)

         WHILE charindex(' ',@FADESCi,@BlanksPOS+1)>0
         BEGIN    

           select @BlanksPOS=charindex(' ',@FADESCi,@BlanksPOS+1)
           
           if @BlanksPOSP is null
           begin
 
             insert into #var_part(var_part,BlanksPOSP)
              select substring(@FADESCi,0,@BlanksPOS-2),0              

           end    
           else
           begin

              insert into #var_part(var_part,BlanksPOSP)
              select substring(@FADESCi,@BlanksPOSP+1,@BlanksPOS-@BlanksPOSP-1),@BlanksPOSP
              
           end

           select @count=@count+1
           select @BlanksPOSP=charindex(' ',@FADESCi,@BlanksPOS)

        
        
        END

        insert into #var_part(var_part,BlanksPOSP)
        select substring(@FADESCi,@BlanksPOSP+1,len(@fadesci)-@BlanksPOSP),@BlanksPOSP
        
        set @ount=1
        set @pass=0
        
        DECLARE Correction_cursor CURSOR FOR
        SELECT var_part,blanksposP from #var_part
        OPEN Correction_cursor


        FETCH NEXT FROM Correction_cursor
        INTO @var_part, @blanksposP1
 
        WHILE @@FETCH_STATUS = 0
        BEGIN

           if ltrim(@var_part) <>''
           begin
              if @pass=0
              begin

                 if len(@var_part)=1 and isnumeric(@var_part)=1
                 begin
                    select @EXECSTRING=@EXECSTRING + ' right(var_desc,3) <>''_al''' + ' and (charindex('' ' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ''',var_desc,0)>0)'
                    select @EXECSTRING2=@EXECSTRING2 + ' right(var_desc,3) <>''_al''' + ' and (charindex('' ' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ''',var_desc,0)>0)'

                 end
                 else
                 begin
                    if len(@var_part)=1 and isnumeric(@var_part)=0
                    begin
                       select @EXECSTRING=@EXECSTRING + ' right(var_desc,3) <>''_al''' + ' and charindex('' ' + @var_part + ' '',var_desc,0) >0'
                       select @EXECSTRING2=@EXECSTRING2 + ' right(var_desc,3) <>''_al''' + ' and charindex('' ' + @var_part + ' '',var_desc,0) >0'
                    end
                    else
                    begin
                       select @EXECSTRING=@EXECSTRING + ' right(var_desc,3) <>''_al''' + ' and (charindex(''' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ''',var_desc,0) >0 or charindex('' ' + @var_part + ' '',var_desc,0) >0)'
		       select @EXECSTRING2=@EXECSTRING2 + ' right(var_desc,3) <>''_al''' + ' and (charindex(''' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ''',var_desc,0) >0 or charindex('' ' + @var_part + ' '',var_desc,0) >0)'
                    end
                 end  
              end
              else
              begin

                 if @ount=(select count(var_part) from #VAR_PART)
                 begin    
                    if len(@var_part)=1 and isnumeric(@var_part)=1
                    begin
                       select @EXECSTRING=@EXECSTRING+' and ' + '(charindex('' ' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ''',var_desc,0) >0)' + ' and len(var_desc)<=len(''' + @FADESCi +''')'
                       select @EXECSTRING2=@EXECSTRING2+' and ' + '(charindex('' ' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ''',var_desc,0) >0)' + ' and len(var_desc)<=len(''' + @FADESCi +''')'
                    end
                    else
                    begin    
                       if len(@var_part)=1 and isnumeric(@var_part)=0
                       begin
                          select @EXECSTRING=@EXECSTRING+' and ' + 'charindex('' ' + @var_part + ' '',var_desc,0) >0' + ' and len(var_desc)<=len(''' + @FADESCi +''')'
                          select @EXECSTRING2=@EXECSTRING2+' and ' + 'charindex('' ' + @var_part + ' '',var_desc,0) >0' + ' and len(var_desc)<=len(''' + @FADESCi +''')'
                       end
                       else
                       begin
                          select @EXECSTRING=@EXECSTRING+' and ' + '(charindex('' ' + @var_part + ''',var_desc,0) >0 or charindex(''' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ' '',var_desc,0) >0)' + ' and len(var_desc)<=len(''' + @FADESCi +''')'
                          select @EXECSTRING2=@EXECSTRING2+' and ' + '(charindex('' ' + @var_part + ''',var_desc,0) >0 or charindex(''' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ' '',var_desc,0) >0)' + ' and len(var_desc)<=len(''' + @FADESCi +''')'
                       end
                    end
                 end
                 else
                 begin
                    if len(@var_part)=1 and isnumeric(@var_part)=1
                    begin
                       select @EXECSTRING=@EXECSTRING+' and ' + '(charindex('' ' + @var_part + ' '',var_desc,0)>0 or charindex('' ' + @var_part + ''',var_desc,0) >0)'
                       select @EXECSTRING2=@EXECSTRING2+' and ' + '(charindex('' ' + @var_part + ' '',var_desc,0)>0 or charindex('' ' + @var_part + ''',var_desc,0) >0)'
                    end
                    else
                    begin
                       if len(@var_part)=1 and isnumeric(@var_part)=0
                       begin
                          select @EXECSTRING=@EXECSTRING+' and ' + 'charindex('' ' + @var_part + ' '',var_desc,0) >0'
                          select @EXECSTRING2=@EXECSTRING2+' and ' + 'charindex('' ' + @var_part + ' '',var_desc,0) >0'

                       end
                       else
                       begin
                          select @EXECSTRING=@EXECSTRING+' and ' + '(charindex('' ' + @var_part + ''',var_desc,0) >0 or charindex(''' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ' '',var_desc,0) >0)'
                          select @EXECSTRING2=@EXECSTRING2+' and ' + '(charindex('' ' + @var_part + ''',var_desc,0) >0 or charindex(''' + @var_part + ' '',var_desc,0) >0 or charindex('' ' + @var_part + ' '',var_desc,0) >0)'
 
                      end
                    end      
                 end
              end
              set @pass=1
           end
           set @ount=@ount+1
        FETCH NEXT FROM Correction_cursor
        INTO @var_part, @blanksposP1
        END
        CLOSE Correction_cursor
        DEALLOCATE Correction_cursor
        
        select @STRF= 'update #TEMPvariables_AL set varcount=(' + @EXECSTRING2 +') where alarm_id=' + convert(varchar(10),@FAID)
	exec(@STRF)
        set @STRF=''
        select @STRF= 'update #TEMPvariables_AL set Corrected_extended_info=(' + @EXECSTRING +') where alarm_id=' + convert(varchar(10),@FAID) + ' and varcount=1' 
           exec(@STRF)
        

        if (select corrected_extended_info from  #TEMPvariables_AL where alarm_id=@FAID)-
           (select alarm_extinfo from  #TEMPvariables_AL where alarm_id=@FAID)=0
        begin
	   update #TEMPvariables_AL set tobecorrected='NO' where alarm_id=@FAID
        end
        else 
           update #TEMPvariables_AL set tobecorrected='MISSMATCH' where alarm_id=@FAID




/*debug
--print left(@STRF,256)
--if len(@STRF) >256
--print right(@STRF,len(@STRF)-256)
--exec('if (' + @EXECSTRING +') is null begin exec(' + @STRF +') end)'
*/     


























     end
  end
  else  --MATCH FOR AL
  begin
     if @EIFO is null --WE HAVE TO UPDATE
        update #TEMPvariables_AL set 
        corrected_extended_info=convert(varchar(20),@SAID),
        corrected_var_desc=@SDESC,
        corrected_group=@SGRP,
        tobecorrected='YES'
        where alarm_id=@FAID
     else
     begin  --VERIFY IF WE HAVE TO UPDATE EXTENDED_INFO --NO
        if @SAID=convert(int,@EIFO) 
           update #TEMPvariables_AL set
           tobecorrected='NO'
           where alarm_id=@FAID
        else
           update #TEMPvariables_AL set   --YES
           corrected_extended_info=@SAID,
           corrected_var_desc=@SDESC,
           corrected_group=@SGRP,
           tobecorrected='YES'
           where alarm_id=@FAID
       end

    end


FETCH NEXT FROM FindVAR_cursor
INTO @FAID,@FADESC,@SAID,@EIFO,@SDESC,@SGRP
END

CLOSE FindVAR_cursor
DEALLOCATE FindVAR_cursor



update #TEMPvariables_AL set corrected_var_desc=(select var_desc from variables_base WITH(NOLOCK)
where var_id=corrected_extended_info)

update #TEMPvariables_AL set corrected_group=(select pu.pug_desc from pu_groups pu WITH(NOLOCK) join
variables_base v WITH(NOLOCK) on pu.pug_id=v.pug_id
where v.var_id=corrected_extended_info)

--update #TEMPvariables_AL set ToBeCorrected='NO' where source_var_desc= 
--left(Alarm_desc,len(alarm_desc)-3)


--update #TEMPvariables_AL set ToBeCorrected='YES' where corrected_var_desc
--is not null


DECLARE Update_cursor CURSOR FOR
SELECT alarm_id,Alarm_desc from #TEMPvariables_AL where ToBeCorrected='YES'

OPEN Update_cursor


FETCH NEXT FROM Update_cursor
INTO @CAID, @CADE

WHILE @@FETCH_STATUS = 0
BEGIN

   if (select count(var_id) from variables_base WITH(NOLOCK) where var_desc = left(@CADE,len(@CADE)-3)and pu_id=@pu_id)>1
   begin
      PRINT 'Alarm Var_desc ' + @CADE + ', Alarm Var_id ' + convert(varchar(25),@CAID) + ' Has multiple corresponding var_desc'
      return
   end

   else
   begin
   
      set @str='update variables set extended_info = ' + 
      (select convert(varchar(10),Corrected_extended_info) from  #TEMPvariables_AL where alarm_id=@CAID and Corrected_extended_info is not null) +
      ' Where var_id = ' + convert(varchar(10),@CAID)

      insert into #ListC(update_str)
      values (@str)

      if @UL= 'repair' and @str is not null
         exec(@str)
   end

FETCH NEXT FROM Update_cursor
INTO @CAID, @CADE
END

CLOSE Update_cursor
DEALLOCATE Update_cursor





--DEPENDING ON THE INPUT...

if @UL = 'list'
   select * from #TEMPvariables_AL order by tobecorrected


if @UL='list_corrections'
select * from #ListC where update_str is not null

if @UL='no_match'
select * from #TEMPvariables_AL where tobecorrected='MISSMATCH'--and Corrected_extended_info is null


drop table #TEMPvariables_AL
drop table #VAR_PART
drop table #ListC
drop table #TEMPvariables




