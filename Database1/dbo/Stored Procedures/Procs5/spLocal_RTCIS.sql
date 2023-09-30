    CREATE procedure dbo.spLocal_RTCIS   
@OutputValue varchar(25) OUTPUT,  
@Pu_Id  int,  
@Var_Id  int,  
@Event_Id  int,  
@End_Time datetime  
AS  
  
Declare  @AppProdId  int,  
 @Prod_Code  varchar(25),  
 @Prod_Id  int,  
 @Weight varchar(25),  
 @Weight_Var_Id int,  
 @Roll_Pos varchar(1),  
 @Sequence varchar(3),  
 @Team  varchar(1),  
 @Roll_Num varchar(25),  
 @Status int  
  
  
Select @Weight_Var_Id = var_id from variables where extended_info like '%Waste RollStatus%'  
Select @Weight = result from tests where result_on = @End_Time and Var_Id = @Weight_Var_Id  
Select @Weight = Convert(varchar(25),Convert(int,((convert(float,@Weight) * 2000) * 2.2046)))  
Select @Prod_Id = NULL  
Select @Prod_Id = Applied_Product From Events Where (PU_Id = @Pu_Id) And (TimeStamp = @End_Time)  
If (@Prod_Id Is Not NULL)  
  Select @Prod_Id = @Prod_Id  
Else  
  Select @Prod_Id = Prod_Id  
    From Production_Starts  
    Where (PU_Id = @Pu_Id) And  
          (Start_Time < @End_Time) And   
          ((End_Time >= @End_Time) Or (End_Time Is Null))  
  
Select @Prod_Code = right(ltrim(rtrim(Prod_Code)),8) from products where prod_id = @Prod_Id  
  
Select @Roll_Num = Event_Num from events where event_id = @Event_Id  
  
  
Select @Roll_Pos  = SUBSTRING(@Roll_Num,7,1)  
Select @Sequence = SUBSTRING(@Roll_Num,4,3)  
Select @Team = SUBSTRING(@Roll_Num,3,1)  
  
Delete From Spectra2 where LCLMOD_DATE < DATEADD(dd, -5, getdate())  
Select @Status = event_status  from events where event_id = @Event_id  
  
If @Status = 18  
Begin  
 Insert Into Spectra2 (MSGTYP,MSGINT,TRXCOD,SUBSIT,FROM_LOC,TO_LOC,ITMCLS,ITMCOD,CODDAT,PRODAT,EXPDAT,CASQTY,ULPALL,ULIDCD,UL_STACOD,PRDORD,BYPCOD,SLDFLG,DELVCD,MACHID,TEAMID,TRNOVR,FRTBCK,PRTLBL,HOSTID,HOST_REC,MSTAMP,ERRCOD,CTRL_DATE,CTRL_USER,LCLSENT,LCLMESSAGE,LCLMOD_DATE)  
 Values (3,'M','04','0','2M','PM2M','P',@Prod_Code,null,@End_Time,Null,@Weight,Null,Null,14,Null,Null,Null,Null,'2M',@Team,@Sequence,@Roll_Pos,'Y','SPCTR1',100,@End_Time,'A',Getdate(),'Prof',Null,Null,Getdate())  
End  
  
--exec SENDTOORACLE  
--exec CHECKRTCISRESULTS  
  
Select @OutputValue = ''  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
