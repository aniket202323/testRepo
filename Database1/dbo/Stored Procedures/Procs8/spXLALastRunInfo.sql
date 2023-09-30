Create Procedure dbo.spXLALastRunInfo @puid integer, 
 	  	  	 @prodid integer,
 	  	  	 @groupid integer,
 	  	  	 @propid integer,
 	  	  	 @charid integer
 	  	  	 , @InTimeZone 	 varchar(200) = null
 AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
  Declare @tmpSQL1 varchar(4000)
  Declare @tmpSQL2 varchar(4000)
-- INITIALIZE to empty strings so as to prevent "concatenation with NULL" problem
-- MSi/MT/2-28-2001 
  SELECT @tmpSQL1 = ''
  SELECT @tmpSQL2 = ''
  Select @tmpSQL1 = 'select RSum_Id,Comment_Id,Conf_Index,Duration,End_Time = End_Time at time zone '''+@DBTz+''' at time zone ''' + Isnull(@InTimeZone,'Null') + ''',
 	  	  	 In_Limit,In_Warning,Prod_Id,PU_Id,Start_Time = Start_Time at time zone '''+@DBTz+''' at time zone ''' + Isnull(@InTimeZone,'Null') + '''  from gb_rsum WITH (INDEX(rsum_by_pu)) where pu_id = ' + Convert(varchar(50),@puid) +
       ' and end_time = (select max(end_time) from gb_rsum WITH (INDEX(rsum_by_product)) where pu_id = ' + 
       Convert(varchar(50),@puid) 
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
  Select @tmpSQL2 = @tmpSQL2 + ')'
  Exec (@tmpSQL1 + @tmpSQL2)
