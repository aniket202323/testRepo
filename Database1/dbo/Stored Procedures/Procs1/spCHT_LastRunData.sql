Create Procedure dbo.spCHT_LastRunData  @puid integer, 
 	 @varid integer, 
 	 @prodid integer,
 	 @groupid integer,
 	 @propid integer,
 	 @charid integer
 AS
  Declare @tmpSQL1 nvarchar(255)
  Declare @tmpSQL2 nvarchar(255)
  Declare @tmpSQL3 nvarchar(255)
/* *********************************************************
   Initialization to empty string so as to avoid null string 
   **********************************************************/
Select @tmpSQL1 = ''
Select @tmpSQL2 = ''
Select @tmpSQL3 = ''
  Select @tmpSQL1 = 'Select rs.start_time, rs.end_time, rs.prod_id, rsd.* ' +
      'From gb_rsum rs  With(index(rsum_by_pu)) join gb_rsum_data rsd with(index(gb_rsum_data_by_id)) ' +
      'on rsd.rsum_id = rs.rsum_id Where rs.pu_id = ' + Convert(nvarchar(50),@puid) + 
      ' and rsd.var_id = ' + Convert(nvarchar(50),@varid) + ' and rs.start_time = '
  Select @tmpSQL3 = '(Select max(start_time) From gb_rsum With(index(rsum_by_product)) Where pu_id = ' + 
 	 Convert(nvarchar(50),@puid)
  if @prodid Is Not Null
    Select @tmpSQL2 = ' And prod_id = ' + Convert(nvarchar(50),@prodid)
  else if @groupid Is Not Null and @propid Is Null
    Select @tmpSQL2 = ' And prod_id in (Select prod_id ' +
 	    'from product_group_data where product_grp_id = ' + Convert(nvarchar(50),@groupid) + ')'
  else if @groupid Is Null and @propid Is Not Null
    Select @tmpSQL2 = ' And prod_id in (Select prod_id ' +
 	    'from pu_characteristics where prop_id = ' + Convert(nvarchar(50),@propid) 
 	    + ' and char_id = ' + Convert(nvarchar(50),@charid) + ')'
  else if @groupid Is Not Null and @propid Is Not Null
    Select @tmpSQL2 = ' And prod_id in (Select C.prod_id ' +
 	    'from pu_characteristics C join product_group_data G on C.prod_id = G.prod_id ' +
 	    'where prop_id = ' + Convert(nvarchar(50),@propid) + ' and char_id = ' 
 	    + Convert(nvarchar(50),@charid) + ' and product_grp_id = ' + Convert(nvarchar(50),@groupid) + ')'
  Select @tmpSQL2 = @tmpSQL2 + ')'
  Exec (@tmpSQL1 + @tmpSQL3 + @tmpSQL2)
