CREATE PROCEDURE dbo.spEM_ShowCacheStats
 AS
Declare
  @@InstanceName nvarchar(255),
  @@ServiceId int,
  @ModifiedOn datetime,
  @Hits decimal(12,2),
  @Misses decimal(12,2),
  @Refils decimal(12,2),
  @HitPct decimal(12,2),
  @MaxVars decimal(12,2),
  @ValsPerVar decimal(12,2),
  @MissTooOld decimal(12,2),
  @MissNotCached decimal(12,2),
  @VarsRequested decimal(12,2),
  @VarsCached decimal(12,2),
  @PctFullVars decimal(12,2),
  @PctFullData decimal(12,2),
  @ServiceDesc nvarchar(30),
  @StartTime 	 DateTime,
  @KeyId 	  	 Int
Create Table #CacheStats (ServiceDesc nvarchar(255), InstanceName nvarchar(255), HitPct decimal(12,2), Hits decimal(12,2), Misses decimal(12,2), Refils decimal(12,2),MaxVars decimal(12,2) NULL,ValsPerVar decimal(12,2)NULL, MissTooOld decimal(12,2)NULL ,MissNotCached decimal(12,2)NULL, VarsRequested decimal(12,2) NULL,VarsCached decimal(12,2)NULL, PctFullVars decimal(12,2)NULL, PctFullData decimal(12,2)NULL )
Declare CacheStat_Cursor INSENSITIVE CURSOR
  For Select Distinct Instance_Name,Service_Id from Performance_Statistics_Keys Where (Object_Id = 2) Order By Service_Id
  For Read Only
  Open CacheStat_Cursor  
Fetch_Loop:
  Fetch Next From CacheStat_Cursor Into @@InstanceName,@@ServiceId
  If (@@Fetch_Status = 0)
    Begin
      Select @StartTime = NULL
      Select @StartTime = max (Start_Time) from Performance_Statistics_Keys Where (Object_Id = 2) and (Counter_Id = 0) And (Instance_Name = @@InstanceName) And (Service_Id = @@ServiceId)
      If (@StartTime Is NULL)
        Goto Fetch_Loop
      Select @KeyId = NULL
      Select @KeyId=Key_Id from Performance_Statistics_Keys Where (Key_Id = @KeyId)
      If (@KeyId Is NULL)
        Goto Fetch_Loop
      Select @ModifiedOn = NULL
      Select @ModifiedOn = Max(Modified_On) From Performance_Statistics Where (Key_Id = @KeyId)
      If (@ModifiedOn Is NULL)
        Goto Fetch_Loop
      Select @ServiceDesc = Service_Desc From CXS_Service Where (Service_Id = @@ServiceId)
      Select @Hits = NULL
      Select @Misses = NULL
      Select @HitPct = NULL
      Select @Refils = NULL
      Select @MaxVars = NULL
      Select @ValsPerVar = NULL
      Select @MissTooOld = NULL
      Select @MissNotCached = NULL
      Select @VarsRequested = NULL
      Select @VarsCached = NULL
      Select @PctFullVars = NULL
      Select @PctFullData = NULL
      Select @KeyId        = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 2) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @HitPct       = Convert(decimal(12,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId        = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 2) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @Hits         = Convert(decimal(12,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId        = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 2) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @Refils       = Convert(decimal(12,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId        = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 2) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @MaxVars      = Convert(decimal(12,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId        = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 2) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @ValsPerVar   = Convert(decimal(12,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId        = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 2) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @MissTooOld   = Convert(decimal(12,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId        = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 2) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @MissNotCached= Convert(decimal(12,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId        = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 2) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @VarsRequested= Convert(decimal(12,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId        = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 2) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @VarsCached   = Convert(decimal(12,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId        = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 2) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @PctFullVars  = Convert(decimal(12,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      Select @KeyId        = Key_Id from Performance_Statistics_Keys Where (Counter_Id = 0) And (Object_Id = 2) And (Service_Id = @@ServiceId) And (Instance_Name = @@InstanceName) and (@StartTime = Start_Time)
      Select @PctFullData  = Convert(decimal(12,2),Value)      From Performance_Statistics Where (Key_Id = @KeyId) And (Modified_On = @ModifiedOn)
      If (@HitPct < 0)   
        Select @HitPct = 0
 	   If (@HitPct > 100)
 	  	 Select @HitPct = 100
      Insert Into #CacheStats (ServiceDesc,InstanceName,Hits,Misses,HitPct,Refils,MaxVars,ValsPerVar,MissTooOld,MissNotCached,VarsRequested,VarsCached,PctFullVars,PctFullData)
 	  	  Values(@ServiceDesc,@@InstanceName,@Hits,@Misses,@HitPct,@Refils,@MaxVars,@ValsPerVar,@MissTooOld,@MissNotCached,@VarsRequested,@VarsCached,@PctFullVars,@PctFullData)
      Goto Fetch_Loop
    End
Close CacheStat_Cursor 
Deallocate CacheStat_Cursor
Select  	 Service = Substring(ServiceDesc,1,20),HitPct, Hits, Misses, MissTooOld,MissNotCached,PctFullData
  From #CacheStats
  Order By HitPct asc,Misses desc
Drop Table #CacheStats
