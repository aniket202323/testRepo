Create Procedure dbo.[spXLARunInfo_Bak_177] 
 	  	 @stime datetime,
 	  	 @etime datetime,
 	  	 @puid integer, 
 	  	 @prodid integer, 
 	  	 @groupid integer,
 	  	 @propid integer,
 	  	 @charid integer,
 	  	 @torder smallint 
  	  	 , @InTimeZone 	 varchar(200) = null
AS
  Declare @tmpSQL1 varchar(4000)
  Declare @tmpSQL2 varchar(4000)
-- INITIALIZE to empty strings so as to prevent "concatenation with NULL" problem
-- MSi/MT/2-28-2001 
  SELECT @tmpSQL1 = ''
  SELECT @tmpSQL2 = ''
SELECT @stime = dbo.fnServer_CmnConvertToDBTime(@stime,@InTimeZone)
SELECT @etime = dbo.fnServer_CmnConvertToDBTime(@etime,@InTimeZone)
  Select @tmpSQL1 = 'select  RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = dbo.fnServer_CmnConvertFromDbTime(End_Time,''' 
 	  	 + ISNULL(@InTimeZone,'NULL') + '''),
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = dbo.fnServer_CmnConvertFromDbTime(Start_Time,''' + ISNULL(@InTimeZone,'NULL') 
 	  	  	 + ''') from gb_rsum WITH (INDEX(rsum_by_product)) Where pu_id = ' + Convert(varchar(50),@puid)
  if @etime is null 
    Select @tmpSQL1 = @tmpSQL1 + ' And Start_Time = ''' + Convert(varchar(50),@stime) + ''''
  else
    Select @tmpSQL1 = @tmpSQL1 + ' And (Start_Time between ''' + Convert(varchar(50),@stime) + 
 	  	 ''' and ''' + Convert(varchar(50),@etime) + ''')' 
  if @prodid Is Not Null
    Select @tmpSQL2 = ' And prod_id = ' + Convert(varchar(50),@prodid)
  else if @groupid Is Not Null and @propid Is Null
    Select @tmpSQL2 = ' And prod_id in (Select prod_id ' +
 	    'from product_group_data where product_grp_id = ' + Convert(varchar(50),@groupid) + ')'
  else if @groupid Is Null and @propid Is Not Null
    Select @tmpSQL2 = ' And prod_id in (Select prod_id ' +
 	    'from pu_characteristics where prop_id = ' + Convert(varchar(50),@propid) 
 	    + ' and char_id = ' + Convert(varchar(50),@charid) + ')'
  else if @groupid Is Not Null and @propid Is Not Null
    Select @tmpSQL2 = ' And prod_id in (Select C.prod_id ' +
 	    'from pu_characteristics C join product_group_data G on C.prod_id = G.prod_id ' +
 	    'where prop_id = ' + Convert(varchar(50),@propid) + ' and char_id = ' 
 	    + Convert(varchar(50),@charid) + ' and product_grp_id = ' + Convert(varchar(50),@groupid) + ')'
  if @torder = 1 
    Select @tmpSQL2 = @tmpSQL2 + ' Order by Start_Time'
  else
    Select @tmpSQL2 = @tmpSQL2 + ' Order by Start_Time desc'
  Exec (@tmpSQL1 + @tmpSQL2)
