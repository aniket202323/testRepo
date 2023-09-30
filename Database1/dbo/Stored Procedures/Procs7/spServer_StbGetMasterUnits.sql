CREATE PROCEDURE dbo.spServer_StbGetMasterUnits
@SheetId int = 0
AS
Declare
  @TimeStamp Datetime
Select @TimeStamp = dbo.fnServer_CmnGetDate(GetUTCDate())
Declare  @PUId  Table (PU_Id Int)
Declare  @UnitInfo Table(PU_Id int, Prod_Id int, RYear int, RMonth int, RDay int, RHour int, RMin int, RSec int)
if (@SheetId > 0)
 	 Begin
 	  	 Insert into @PUId (PU_Id)
 	  	   Select  Distinct isnull(u.Master_Unit,u.PU_Id)
            from Sheet_Variables s
 	  	   join Variables_Base v on s.Var_Id = v.Var_Id
            join Prod_Units_Base u on u.PU_Id = v.PU_id
            where s.Sheet_Id = @SheetId
 	 insert into @UnitInfo (PU_Id, Prod_Id, RYear, RMonth, RDay, RHour, RMin, RSec)
 	        Select PU_Id = a.PU_Id,
 	               Prod_Id = b.Prod_Id,
 	               RYear = DatePart(Year,b.Start_Time),
 	               RMonth = DatePart(Month,b.Start_Time),
 	               RDay = DatePart(Day,b.Start_Time),
 	               RHour = DatePart(Hour,b.Start_Time),
 	               RMin = DatePart(Minute,b.Start_Time),
 	               RSec = DatePart(Second,b.Start_Time)
 	          From Prod_Units_Base a
 	  	     Join @PUId pu on a.pu_Id = pu.pu_Id  
 	          Join Production_Starts b on b.PU_Id = a.PU_Id
 	          Where (a.Master_Unit Is Null) And
 	                (a.PU_Id > 0) And
 	                (b.Start_Time < @TimeStamp) And
 	                ((b.End_Time >= @TimeStamp) Or (b.End_Time Is Null))
 	 End
Else
 	 insert into @UnitInfo (PU_Id, Prod_Id, RYear, RMonth, RDay, RHour, RMin, RSec)
       Select PU_Id = a.PU_Id,
              Prod_Id = b.Prod_Id,
              RYear = DatePart(Year,b.Start_Time),
              RMonth = DatePart(Month,b.Start_Time),
              RDay = DatePart(Day,b.Start_Time),
              RHour = DatePart(Hour,b.Start_Time),
              RMin = DatePart(Minute,b.Start_Time),
              RSec = DatePart(Second,b.Start_Time)
         From Prod_Units_Base a
         Join Production_Starts b on b.PU_Id = a.PU_Id
         Where (a.Master_Unit Is Null) And
               (a.PU_Id > 0) And
               (b.Start_Time < @TimeStamp) And
               ((b.End_Time >= @TimeStamp) Or (b.End_Time Is Null))
Select PU_Id, Prod_Id, RYear, RMonth, RDay, RHour, RMin, RSec
  From @UnitInfo
  order by PU_Id
