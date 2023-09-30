CREATE PROCEDURE dbo.spXLASearchEvent 
 	 @SearchString varchar(50),
 	 @StartTime datetime,
 	 @EndTime datetime,
 	 @MasterUnit int,
 	 @MasterUnitName varchar(50),
 	 @prodid integer, 
 	 @groupid integer, 
 	 @propid integer, 
 	 @charid integer,
 	 @torder tinyint = NULL
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
declare @QueryType tinyint
If @StartTime Is Null
  Select @StartTime = '1-jan-1971'
If @EndTime Is Null
  Select @EndTime = dateadd(day,7,getdate())
SELECT @StartTime = @StartTime at time zone @InTimeZone at time zone @DBTz 
SELECT @EndTime = @EndTime at time zone @InTimeZone at time zone @DBTz 
/*  ------------------------------------------------
    Assign @MasterUnit As Either Master or Slave
    ------------------------------------------------ */
If @MasterUnitName Is Not Null
    Select @MasterUnit = Case When Master_Unit Is Null Then PU_Id Else Master_Unit End 
    From   Prod_Units 
    Where  PU_Desc = @MasterUnitName  
Else If @MasterUnit Is Not Null
    Select @MasterUnit = Case When Master_Unit Is Null Then PU_Id Else Master_Unit End 
    From   Prod_Units 
    Where  PU_Id = @MasterUnit  
create table #prod_starts (pu_id int, prod_id int, start_time datetime, end_time datetime NULL)
--Figure Out Query Type
if @prodid is not null
  select @QueryType = 1  --Single Product
else if @groupid is not null and @propid is null 
  select @QueryType = 2  --Single Group
else if @propid is not null and @groupid is null
  select @QueryType = 3  --Single Characteristic
else if @propid is not null and @groupid is not null
  select @QueryType = 4  --Group and Property  
else
  select @QueryType = 5
/*  Build TempTable (#Prod_Starts) based on 
    times and the kind of products specified  
    ---------------------------------------- */
if @QueryType = 5 	  	  	 --All products
  BEGIN
    if @MasterUnit Is Null
      BEGIN
        insert into #prod_starts
        select ps.pu_id, ps.prod_id, ps.start_time, ps.end_time
        from   production_starts ps
        where  (   start_time Between @starttime And @endtime 
 	  	  OR end_time Between @starttime And @endtime 
 	  	  OR ( start_time <= @starttime AND (end_time > @endtime OR end_time is null) )
 	  	   	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
               )
       END
    Else
      BEGIN
        insert into #prod_starts
        select ps.pu_id, ps.prod_id, ps.start_time, ps.end_time
        from   production_starts ps
        where  pu_id = @MasterUnit 
 	 And    (    start_time Between @starttime And @endtime
 	  	  OR end_time Between @starttime And @endtime
 	  	  OR ( start_time <= @starttime AND (end_time > @endtime OR end_time is null) )
 	  	     --Start_time & End_time condition checked ; MSi/MT/3-21-2001
               )
      END 
  END
Else if @QueryType = 1 	  	  	 --Single Product
  BEGIN
    if @MasterUnit Is Null
      BEGIN
        insert into #prod_starts
        select ps.pu_id, ps.prod_id, ps.start_time, ps.end_time
        from   production_starts ps
        where  prod_id = @prodid 
 	 And    (    start_time Between @starttime And @endtime
 	  	  Or end_time Between @starttime And @endtime
 	  	  Or ( start_time <= @starttime AND (end_time > @endtime OR end_time is null) )
 	   	     --Start_time & End_time condition checked ; MSi/MT/3-21-2001
               )
      END
    Else
      BEGIN
        insert into #prod_starts
        select ps.pu_id, ps.prod_id, ps.start_time, ps.end_time
        from   production_starts ps
        where  pu_id = @MasterUnit 
 	 And    prod_id = @prodid 
 	 And    (    start_time Between @starttime And @endtime
 	  	  OR end_time Between @starttime And @endtime
 	  	  OR ( start_time <= @starttime AND (end_time > @endtime OR end_time is null) )
 	   	     --Start_time & End_time condition checked ; MSi/MT/3-21-2001
               )
      END 
  END
Else
  BEGIN
    create table #products (prod_id int)
    if @QueryType = 2 	  	  	 --Single Product Group
      BEGIN
         insert into #products
         select prod_id
         from   product_group_data
         where  product_grp_id = @groupid
      END
    else if @QueryType = 3 	  	 --Single Characteristic
      BEGIN
         insert into #products
         Select distinct prod_id 
 	  from   pu_characteristics 
         where  prop_id = @propid 
 	  And    char_id = @charid
      END
    Else 	  	  	  	 --must be QueryType=4 (Group and Property)
      BEGIN
         insert into #products
         select prod_id
         from   product_group_data
         where  product_grp_id = @groupid
 	  insert into #products
         Select distinct prod_id 
 	  from   pu_characteristics 
         where  prop_id = @propid 
 	  And    char_id = @charid
      END
    if @MasterUnit Is Null
      BEGIN
        insert into #prod_starts
        select ps.pu_id, ps.prod_id, ps.start_time, ps.end_time
        from   production_starts ps
        join   #products p on ps.prod_id = p.prod_id 
        where  (    start_time Between @starttime And @endtime
 	  	  Or end_time Between @starttime And @endtime
 	  	  OR ( start_time <= @starttime AND (end_time > @endtime OR end_time is null) )
 	   	     --Start_time & End_time condition checked ; MSi/MT/3-21-2001
               ) 
      END
    Else
      BEGIN
        insert  into #prod_starts
        select  ps.pu_id, ps.prod_id, ps.start_time, ps.end_time
        from    production_starts ps
        join    #products p on ps.prod_id = p.prod_id 
        where   pu_id = @MasterUnit 
 	 And     (    start_time between @starttime and @endtime
 	  	   Or end_time Between @starttime And @endtime
 	  	   OR ( start_time <= @starttime AND (end_time > @endtime OR end_time is null) )
 	   	      --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                ) 
      END  
    drop table #products
  END
/*  Retrieve the stuff we need From TempTable 
    (#Prod_Starts) based on parameters specified
    --------------------------------------------- */
If @SearchString Is Null
  BEGIN
    If @MasterUnit Is Null 	 --all products
      BEGIN
        If @torder = 1
            Select    Primary_Event_Num = e.Event_Num
 	  	     , Event_Id = e.Event_Id
 	  	     , TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
 	  	     , Original_Product = p.Prod_Code 
 	  	     , Applied_Product = p2.Prod_Code
 	  	     , Production_Unit = pu.Pu_Desc
            From      Events e
 	  	   	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            Join      #Prod_Starts ps ON ps.PU_Id = e.PU_Id AND ps.Start_Time <= e.TimeStamp AND (ps.end_time > e.TimeStamp OR ps.end_time Is Null)
            Join      Products p ON p.Prod_Id = ps.Prod_Id
            join      Prod_Units pu ON pu.pu_id = e.pu_id
 	     LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
            Where     e.TimeStamp Between @StartTime And @EndTime
            Order By  e.TimeStamp ASC, e.Event_Num 
        Else 	 --Descending Order
            Select    Primary_Event_Num = e.Event_Num
 	  	     , Event_Id = e.Event_Id
 	  	     , TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
 	  	     , Original_Product = p.Prod_Code
 	  	     , Applied_Product = p2.Prod_Code
 	  	     , Production_Unit = pu.pu_desc
            From      Events e
 	  	   	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            Join      #Prod_Starts ps ON ps.PU_Id = e.PU_Id AND ps.Start_Time <= e.TimeStamp AND (ps.end_time > e.TimeStamp OR ps.end_time Is Null)
            Join      Products p on p.Prod_Id = ps.Prod_Id
            join      Prod_Units pu on pu.pu_id = e.pu_id
 	     LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
            Where     e.TimeStamp Between @StartTime And @EndTime
            Order By  e.TimeStamp DESC, e.Event_Num
      END
    Else 	  	  	 --the specified kind of product(s)
      BEGIN
        If @torder = 1
            Select    Primary_Event_Num = e.Event_Num
 	  	     , Event_Id = e.Event_Id
 	             , TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
 	  	     , Original_Product = p.Prod_Code
 	  	     , Applied_Product = p2.Prod_Code
 	  	     , Production_Unit = pu.pu_desc
            From      Events e
 	  	       	  	  	  	               --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            Join      #Prod_Starts ps on ps.PU_Id = e.PU_Id AND ps.Start_Time <= e.TimeStamp AND (ps.end_time > e.TimeStamp OR ps.end_time Is Null)
            Join      Products p ON p.Prod_Id = ps.Prod_Id
            join      Prod_Units pu ON pu.pu_id = e.pu_id
 	     LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
            Where     e.PU_Id = @MasterUnit 
 	     And       e.TimeStamp Between @StartTime And @EndTime
            Order By  e.TimeStamp ASC, e.Event_Num 
        Else 	 --Descending order
            Select    Primary_Event_Num = e.Event_Num
 	  	     , Event_Id = e.Event_Id
 	  	     , TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
 	  	     , Original_Product = p.Prod_Code
 	  	     , Applied_Product = p2.Prod_Code
 	  	     , Production_Unit = pu.pu_desc
            From      Events e
 	  	  	  	  	  	  	   	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            Join      #Prod_Starts ps ON ps.PU_Id = e.PU_Id AND ps.Start_Time <= e.TimeStamp AND (ps.end_time > e.TimeStamp OR ps.end_time Is Null)
            Join      Products p on p.Prod_Id = ps.Prod_Id
            join      Prod_Units pu on pu.pu_id = e.pu_id
 	     LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
            Where     e.PU_Id = @MasterUnit 
 	     And       e.TimeStamp Between @StartTime And @EndTime
            Order By  e.TimeStamp DESC, e.Event_Num 
      END 
  END
Else 	 --Search string not null
  BEGIN
    If @MasterUnit Is Null 	 --All products
      BEGIN
         If @torder = 1
            Select    Primary_Event_Num = e.Event_Num
 	  	     , Event_Id = e.Event_Id
 	  	     , TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
 	  	     , Original_Product = p.Prod_Code
 	  	     , Applied_Product = p2.Prod_Code
 	  	     , Production_Unit = pu.pu_desc
            From      Events e
 	  	  	  	  	  	  	  	   	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            Join      #Prod_Starts ps on ps.PU_Id = e.PU_Id AND ps.Start_Time <= e.TimeStamp AND (ps.end_time > e.TimeStamp OR ps.end_time Is Null)
            Join      Products p ON p.Prod_Id = ps.Prod_Id
            join      Prod_Units pu ON pu.pu_id = e.pu_id
 	     LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
            Where     e.TimeStamp Between @StartTime And @EndTime 
 	     And       e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%' 
            Order By  e.TimeStamp ASC, e.Event_Num 
         Else
            Select    Primary_Event_Num = e.Event_Num
 	  	     , Event_Id = e.Event_Id
 	  	     , TimeStamp =  e.TimeStamp
 	  	     , Original_Product = p.Prod_Code
 	   	     , Applied_Product = p2.Prod_Code
 	  	     , Production_Unit = pu.pu_desc
            From      Events e
 	  	  	  	  	  	  	   	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            Join      #Prod_Starts ps ON ps.PU_Id = e.PU_Id AND ps.Start_Time <= e.TimeStamp AND (ps.end_time > e.TimeStamp OR ps.end_time Is Null)
            Join      Products p ON p.Prod_Id = ps.Prod_Id
            Join      Prod_Units pu ON pu.pu_id = e.pu_id
 	     LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
            Where     e.TimeStamp Between @StartTime And @EndTime 
 	     And       e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%' 
            Order By  e.TimeStamp DESC, e.Event_Num 
      END
    Else 	  	 --specified kind of product(s)
      BEGIN
         If @torder = 1
            Select    Primary_Event_Num = e.Event_Num
 	  	     , Event_Id = e.Event_Id
 	  	     , TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
 	  	     , Original_Product = p.Prod_Code
 	  	     , Applied_Product = p2.Prod_Code
 	  	     , Production_Unit = pu.pu_desc
            From      Events e
 	  	  	  	  	  	  	   	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            Join      #Prod_Starts ps ON ps.PU_Id = e.PU_Id AND ps.Start_Time <= e.TimeStamp AND (ps.end_time > e.TimeStamp OR ps.end_time Is Null)
            Join      Products p on p.Prod_Id = ps.Prod_Id
            join      Prod_Units pu on pu.pu_id = e.pu_id
 	     LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
            Where     e.PU_Id = @MasterUnit 
 	     And       e.TimeStamp Between @StartTime And @EndTime 
 	     And       e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%' 
            Order By  e.TimeStamp ASC, e.Event_Num 
         Else 	 --Ascending order
            Select    Primary_Event_Num = e.Event_Num
 	  	     , Event_Id = e.Event_Id
 	  	     , TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
 	  	     , Original_Product = p.Prod_Code
 	  	     , Applied_Product = p2.Prod_Code
 	  	     , Production_Unit = pu.pu_desc
            From      Events e
 	  	  	  	  	  	  	   	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            Join      #Prod_Starts ps ON ps.PU_Id = e.PU_Id AND ps.Start_Time <= e.TimeStamp AND (ps.end_time > e.TimeStamp OR ps.end_time Is Null)
            Join      Products p on p.Prod_Id = ps.Prod_Id
            join      Prod_Units pu on pu.pu_id = e.pu_id
 	     LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
            Where     e.PU_Id = @MasterUnit 
 	     And       e.TimeStamp Between @StartTime And @EndTime 
 	     And       e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%' 
            Order By  e.TimeStamp DESC, e.Event_Num
      END 
  END
drop table #prod_starts
