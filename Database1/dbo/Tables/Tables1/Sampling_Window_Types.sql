CREATE TABLE [dbo].[Sampling_Window_Types] (
    [Sampling_Window_Type_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Sampling_Window_Type_Data] INT                  NOT NULL,
    [Sampling_Window_Type_Name] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [SamplingWindowTypes_PK_SWTId] PRIMARY KEY CLUSTERED ([Sampling_Window_Type_Id] ASC)
);

