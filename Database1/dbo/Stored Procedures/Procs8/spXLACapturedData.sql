/* NOT CALLED FROM CURRENT EXCEL Addin */
Create Procedure dbo.spXLACapturedData
 	 @varId integer, 
 	 @sTime datetime,
 	 @eTime datetime,
 	 @puId integer, 
 	 @prodId integer,
 	 @groupId integer,
 	 @propId integer,
 	 @charId integer,
 	 @tOrder smallint 
  	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @sTime = @sTime at time zone @InTimeZone at time zone @DBTz  
SELECT @eTime = @eTime at time zone @InTimeZone at time zone @DBTz 
IF @puId Is NUll
 	 SELECT @puId = PU_Id From Variables Where Var_Id = @varId 
  Declare @tmpSQL1 varchar(1000)
  Declare @tmpSQL2 varchar(1000)
  Declare @tmpSQL3 varchar(1000)
-- INITIALIAZE to empty strings so as to prevent "concatenation with NULL" problem
-- MSi/MT/2-28-2001 
  SELECT @tmpSQL1 = ''
  SELECT @tmpSQL2 = ''
  SELECT @tmpSQL3 = ''
  Select @tmpSQL1 = 'select timestamp = ds.timestamp at time zone '''+@DBTz+''' at time zone ''' + Isnull(@InTimeZone,'Null') + ''', ds.prod_id, dsd.* from gb_dset ds  WITH (index(dset_by_pu)) left outer ' + 
       'join gb_dset_data dsd  WITH (index(gb_dset_by_id)) on ds.dset_id = dsd.dset_id and dsd.var_id = ' + 
 	 Convert(varchar(50),@varid) + ' where ds.pu_id = ' + Convert(varchar(50),@puid)
  if @etime is null 
    Select @tmpSQL3 = ' And TimeStamp = ''' + Convert(varchar(50),@stime) + ''''
  else
    Select @tmpSQL3 = ' And (TimeStamp between ''' + Convert(varchar(50),@stime) + 
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
    Select @tmpSQL2 = @tmpSQL2 + ' Order by TimeStamp'
  else
    Select @tmpSQL2 = @tmpSQL2 + ' Order by TimeStamp desc'
  Exec (@tmpSQL1 + @tmpSQL3 + @tmpSQL2)
