Create Procedure dbo.spXLARunDataCalc 
 	   @varid integer
 	 , @stime datetime
 	 , @etime datetime
 	 , @puid integer
 	 , @prodid integer
 	 , @groupid integer
 	 , @propid integer
 	 , @charid integer
 	 , @InTimeZone 	 varchar(200) = null
 AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
  Declare @tmpSQL1 varchar(4000)
  Declare @tmpSQL2 varchar(4000)
  Declare @tmpSQL3 varchar(4000)
-- INITIALIZE to empty strings so as to prevent "concatenation with NULL" problem
-- MSi/MT/2-28-2001 
  SELECT @tmpSQL1 = ''
  SELECT @tmpSQL2 = ''
  SELECT @tmpSQL3 = ''
SELECT @stime = @STime at time zone @InTimeZone at time zone @DBTz 
SELECT @etime = @etime at time zone @InTimeZone at time zone @DBTz 
  Select @tmpSQL1 = 'select RS.start_time at time zone '''+@DBTz+''' at time zone ''' + Isnull(@InTimeZone,'Null') + ''', RS.duration, RSD.* from gb_rsum RS WITH (INDEX(rsum_by_product)) ' +
 	    'join gb_rsum_data RSD WITH (INDEX(gb_rsum_data_by_id)) on RSD.rsum_id = RS.rsum_id and RSD.var_id = ' + Convert(varchar(50),@varid) + 
 	    ' where RS.pu_id = ' + Convert(varchar(50),@puid)  
  if @etime is null 
    Select @tmpSQL3 = ' And Start_Time = ''' + Convert(varchar(50),@stime) + ''''
  else
    Select @tmpSQL3 = ' And (Start_Time between ''' + Convert(varchar(50),@stime) + 
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
  Exec(@tmpSQL1 + @tmpSQL3 + @tmpSQL2)
