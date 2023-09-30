Create Procedure dbo.spXLACapturedInfo 
 	   @stime datetime
 	 , @etime datetime
 	 , @puid integer
 	 , @prodid integer
 	 , @groupid integer
 	 , @propid integer
 	 , @charid integer
 	 , @torder smallint 
  	 , @InTimeZone 	 varchar(200) = null
AS
  --SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
  Declare @tmpSQL1 varchar(1000)
  Declare @tmpSQL2 varchar(1000)
-- INITIALIAZE to empty strings so as to prevent "concatenation with NULL" problem
-- MSi/MT/2-28-2001 
  SELECT @tmpSQL1 = ''
  SELECT @tmpSQL2 = ''
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @stime = @stime at time zone @InTimeZone at time zone @DBTz
SELECT @etime = @etime at time zone @InTimeZone at time zone @DBTz
  Select @tmpSQL1 = 'SELECT DSet_Id,Comment_Id,Operator,Prod_Id,PU_Id,[Timestamp] = [Timestamp] at time zone '''+@DBTz+''' at time zone ''' + Isnull(@InTimeZone,'Null') + ''' from gb_dset WITH (INDEX(dset_by_pu)) Where pu_id = ' + Convert(varchar(50),@puid)
  if @etime is null 
    Select @tmpSQL1 = @tmpSQL1 + ' And TimeStamp = ''' + Convert(varchar(50),@stime) + ''''
  else
    Select @tmpSQL1 = @tmpSQL1 + ' And (TimeStamp between ''' + Convert(varchar(50),@stime) + 
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
 	    'from pu_characteristics C join product_group_data G on C.prod_id = G.prod_id where prop_id = ' +
 	    Convert(varchar(50),@propid) + ' and char_id = ' 
 	    + Convert(varchar(50),@charid) + ' and product_grp_id = ' + Convert(varchar(50),@groupid) + ')'
  if @torder = 1 
    Select @tmpSQL2 = @tmpSQL2 + ' Order by TimeStamp'
  else
    Select @tmpSQL2 = @tmpSQL2 + ' Order by TimeStamp desc'
  Exec (@tmpSQL1 + @tmpSQL2)
