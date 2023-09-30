CREATE PROCEDURE dbo.spBF_SyncMymachinepreferences
As
BEGIN
	IF EXISTS(SELECT 1 FROM Site_Parameters where [Value] = 1 AND Parm_Id =700)
	BEGIN
		Create table #Temp (Dept_Id Int , Dept_desc Varchar(50),Pl_Id Int , Pl_desc Varchar(50),Pu_Id Int , Pu_desc Varchar(50),ET_Id Int , ET_desc Varchar(50),Is_Slave Bit,User_Id int,Flag Int)
		declare @cnt int, @total int,@username varchar(20),@UserId int
		Create table #UserIds (SerialNo Int identity(1,1), User_Id int)
		
		Insert Into #UserIds(User_Id)
		Select User_Id from users_base 
		select top 1 @total = SerialNo from #UserIds Order by SerialNo desc
		SET @cnt =1
		while @cnt <= @total
		BEgin
				Select @UserId=User_id from #UserIds Where SerialNo = @cnt
				IF @UserId IS NOT NULL
				Begin
					Insert into #Temp(Dept_id, Dept_desc,Pl_id,Pl_desc,Pu_id,Pu_desc,ET_Id,ET_desc,IS_Slave)
					EXEC	spBF_APIMyMachines_APIGetMyMachines_Populate
							@UserId;
					UPDATE #Temp SET User_Id = @UserId
					UPDATE T
					SET T.Is_Slave = Case when pu.Master_Unit IS NOT NULL THEN 1 ELSE 0 END
					FRoM #Temp T join Prod_Units_Base Pu on Pu.Pu_id = T.Pu_id 
					UPDATE #Temp SET Flag=2
					Insert into User_Mymachines
					Select * from #temp 
					Delete from #Temp
				END
				Set @cnt = @cnt +1
		End
		UPDATE User_Mymachines SET Flag = 3 where Flag =1;
		UPDATE User_Mymachines SET Flag = 1 where Flag =2;
		DELETE FROM User_Mymachines Where Flag  <> 1;
	END
	UPDATE SITE_Parameters SET [Value] = 0 where parm_Id = 700 and [Value]=1;
End
