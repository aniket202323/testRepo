  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-03  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
  
CREATE PROCEDURE dbo.spLocal_LabSPC  
@OutputValue varchar(25) OUTPUT,  
@Var_id int,  
@PU_Id int,  
@EndTime varchar(30),  
@Numvalues int,  
@UseNull int  
AS  
SET NOCOUNT ON  
  
Declare  
  @Result varchar(25),  
  @IniEndTime datetime,  
  @LoopTimestamp datetime,  
  @PrevEventTime datetime,  
  @MasterUnit int,  
  @LoopNum int,  
  @LabTarget float,  
  @spCalcId int,  
  @Var_IdLab int,  
  @Pu_IdLab int,  
  @Prod_IdLab int,  
  @AppProdId int,  
  @SameSide float,  
  @Over int,  
  @Below int,  
  @MaxLoop int,  
  @LabLL float,  
  @LabUL float,  
  @CurrentResult varchar(25),  
  @Master_PU_IdLab int  
  
  
Select @OutputValue = ''  
Select @IniEndTime = @EndTime  
Select @MasterUnit = Null  
  
Select @MasterUnit = Master_Unit from [dbo].Prod_Units where pu_id = @Pu_Id  
If @MasterUnit is Null  
  Begin  
    select @Masterunit = @Pu_Id  
  End   
  
Select @PrevEventTime = Null  
Select @LoopNum = 1  
Select @MaxLoop  = 1  
  
--- Get the depend variable---Lab  
Select @Var_IdLab = Var_Id From [dbo].calculation_instance_dependencies Where Result_Var_Id = @var_id  
If (@Var_IdLab Is Null)  
  Return  
select @Pu_IdLab = PU_Id from [dbo].variables where var_id = @Var_IdLab  
--- End depend  
  
/* Get the dependent variables Master PU Id */  
Select @Master_PU_IdLab = Master_Unit from [dbo].Prod_Units where pu_id = @Pu_IdLab  
If @Master_PU_IdLab is Null  
  Begin  
    Select @Master_PU_IdLab = @Pu_IdLab  
  End   
  
--- Get the product and the target  
Select @Prod_IdLab = NULL  
Select @Prod_IdLab = Applied_Product From [dbo].Events Where (PU_Id = @Master_Pu_IdLab) And (TimeStamp = @EndTime)  
If (@Prod_IdLab Is Not NULL)  
  Select @Prod_IdLab = @AppProdId  
Else  
  Select @Prod_IdLab = Prod_Id  
    From [dbo].Production_Starts  
    Where (PU_Id = @Master_Pu_IdLab) And  
          (Start_Time < @EndTime) And   
          ((End_Time >= @EndTime) Or (End_Time Is Null))  
  
  
Select @LabUL = U_Reject   from [dbo].var_specs where var_id = @Var_IdLab and prod_id = @Prod_IdLab and Effective_Date <= @EndTime and  ((Expiration_Date > @EndTime) or (Expiration_Date Is Null))  
Select  @Labtarget  = Target from [dbo].var_specs where var_id = @Var_IdLab and prod_id = @Prod_IdLab and Effective_Date <= @EndTime and  ((Expiration_Date > @EndTime) or (Expiration_Date Is Null))  
Select @LabLL = L_Reject    from [dbo].var_specs where var_id = @Var_IdLab and prod_id = @Prod_IdLab and Effective_Date <= @EndTime and  ((Expiration_Date > @EndTime) or (Expiration_Date Is Null))  
  
  
--- Go get the last 7 or Numvalues to check with the target  
select @LoopTimestamp = max(Result_On) from [dbo].tests where Result_On <= @IniEndTime and var_id = @Var_idLab  
  
  
--- get current value  
Select @CurrentResult = Result From [dbo].Tests Where (Var_Id = @Var_IdLab) And (Result_On = @LoopTimestamp)  
  
Select @Over = 0  
Select @Below = 0  
  
While (@LoopNum <= convert(int,@NumValues) and @MaxLoop < 50)  
  Begin  
    Select @Result = NULL  
    Select @Result = Result From [dbo].Tests   
       Where (Result_On = @LoopTimestamp) And (Var_Id = @Var_IdLab)  
      
      
   
    If (@Result is null and @UseNull = 1) goto Next11  
    select @SameSide  = Convert(float, @Result)-@Labtarget  
      
    If (@Sameside >=0)  
      Begin  
        Select @Over = @Over + 1  
      end  
    If (@Sameside < 0)  
      Begin  
        Select @Below = @Below + 1  
      end  
  
    Select @LoopNum = @LoopNum + 1  
   Next11:  
  
    Select @MaxLoop = @MaxLoop + 1  
    select @PrevEventTime = max(Result_On) from [dbo].tests   
   where Result_On < @LoopTimestamp and var_id = @Var_idLab  
  
    Select @LoopTimestamp = @PrevEventTime   
      
  End  
  
If (@CurrentResult > @LabUL)  
  Select @OutputValue = '4'  
else If (@CurrentResult < @LabLL)  
  Select @OutputValue = '4'  
else If (@Below >= @Numvalues)  
  Select @OutputValue = '4'  
else if (@Over >= @Numvalues)  
  
        Select @OutputValue = '4'  
else   
 Select @OutputValue = '1'  
  
SET NOCOUNT OFF  
  
