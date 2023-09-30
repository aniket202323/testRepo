Create Procedure dbo.spXLATestData
 	   @varid 	 integer
 	 , @stime 	 datetime
 	 , @etime 	 datetime
 	 , @puid 	  	 integer
 	 , @prodid 	 integer
 	 , @groupid 	 integer
 	 , @propid 	 integer
 	 , @charid 	 integer
 	 , @torder 	 smallint
 	 , @InTimeZone 	 varchar(200) = null
 AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
declare @QueryType tinyint
SELECT @stime = @STime at time zone @InTimeZone at time zone @DBTz 
SELECT @etime = @etime at time zone @InTimeZone at time zone @DBTz 
IF @puid Is Null
 	 SELECT @puid = PU_Id From Variables Where Var_Id = @varid 
-- TestsData By Specific Time; return data regardless of Canceled = 0 or 1
if @etime is null
  begin
    select t.Test_Id,t.Array_Id,t.Canceled,t.Comment_Id,t.Entry_By
 	  	  	 ,Entry_On = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 ,t.Event_Id,t.Locked,t.Result
 	  	  	 ,Result_On = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 ,t.Second_User_Id,t.Signature_Id,t.Var_Id ,ps.prod_id
    from tests t
 	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
    join production_starts ps ON ps.pu_id = @puid AND ps.start_time <= t.result_on AND ((ps.end_time > t.result_on) OR (ps.end_time is null))
    where t.var_id = @varid and t.result_on = @stime
    return
  end
--EndIf
create table #prod_starts (prod_id int, start_time datetime, end_time datetime NULL)
--Figure Out Query Type
if @prodid is not null
  select @QueryType = 1   	  	 --Single Product
else if @groupid is not null and @propid is null 
  select @QueryType = 2   	  	 --Single Group
else if @propid is not null and @groupid is null
  select @QueryType = 3   	  	 --Single Characteristic
else if @propid is not null and @groupid is not null
  select @QueryType = 4   	  	 --Group and Property  
else
  select @QueryType = 5
select t.*
  into #tests 
  from tests t
  where var_id = @varid and
        result_on >= @stime and
        result_On <= @etime
if @QueryType = 5 
  begin
    insert into #prod_starts
    select ps.prod_id, ps.start_time, ps.end_time
      from production_starts ps
      where pu_id = @puid and
            ((start_time between @stime and @etime) or
             (end_time between @stime and @etime) or 
             (start_time <= @stime and (end_time > @etime or end_time is null))
 	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ) 
  end
else if @QueryType = 1
  begin
    insert into #prod_starts
    select ps.prod_id, ps.start_time, ps.end_time
      from production_starts ps
      where pu_id = @puid and
            prod_id = @prodid and
            ((start_time between @stime and @etime) or
             (end_time between @stime and @etime) or 
             (start_time <= @stime and (end_time > @etime or end_time is null))
 	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ) 
  end
else
  begin
    create table #products (prod_id int)
    if @QueryType = 2 
      begin
         insert into #products
           select prod_id
             from product_group_data
             where product_grp_id = @groupid
      end
    else if @QueryType = 3
      begin
         insert into #products
           Select distinct prod_id 
 	      from pu_characteristics 
             where prop_id = @propid and  
 	            char_id = @charid
      end
    else
      begin
         insert into #products
           select prod_id
             from product_group_data
             where product_grp_id = @groupid
         insert into #products
           Select distinct prod_id 
 	      from pu_characteristics 
             where prop_id = @propid and  
 	            char_id = @charid
      end  
    insert into #prod_starts
    select ps.prod_id, ps.start_time, ps.end_time
      from production_starts ps
      join #products p on ps.prod_id = p.prod_id 
      where pu_id = @puid and
            ((start_time between @stime and @etime) or
             (end_time between @stime and @etime) or 
             (start_time <= @stime and (end_time > @etime or end_time is null))
 	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ) 
    drop table #products
  end
if @torder = 1 
  select  t.Test_Id,t.Array_Id,t.Canceled,t.Comment_Id,t.Entry_By
 	  	  	 ,Entry_On = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 ,t.Event_Id,t.Locked,t.Result
 	  	  	 ,Result_On = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 ,t.Second_User_Id,t.Signature_Id,t.Var_Id ,ps.prod_id
    from #tests t
    join #prod_starts ps 
 	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
      ON ps.start_time <= t.result_on AND ((ps.end_time > t.result_on) or (ps.end_time is null)) and
       t.canceled = 0
    order by result_on
else
      select t.Test_Id,t.Array_Id,t.Canceled,t.Comment_Id,t.Entry_By
 	  	  	 ,Entry_On = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 ,t.Event_Id,t.Locked,t.Result
 	  	  	 ,Result_On = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 ,t.Second_User_Id,t.Signature_Id,t.Var_Id ,ps.prod_id 
    from #tests t
    join #prod_starts ps 
 	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
      on (ps.start_time <= t.result_on and (ps.end_time > t.result_on or ps.end_time is null)) and 
       t.canceled = 0
    order by result_on desc
drop table #tests
drop table #prod_starts
