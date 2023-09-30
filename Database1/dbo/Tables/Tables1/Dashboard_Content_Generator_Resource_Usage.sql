CREATE TABLE [dbo].[Dashboard_Content_Generator_Resource_Usage] (
    [Dashboard_Content_Generator_Resource_Usage_ID] INT        IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Dashboard_CG_CPU_Usage]                        FLOAT (53) NOT NULL,
    [Dashboard_CG_Handle_Count]                     INT        NOT NULL,
    [Dashboard_CG_PageFaults_per_sec]               INT        NOT NULL,
    [Dashboard_CG_Private_Memory]                   INT        NOT NULL,
    [Dashboard_CG_Thread_Count]                     INT        NOT NULL,
    [Dashboard_CG_Virtual_Memory]                   INT        NOT NULL,
    [Dashboard_CG_Virtual_Memory_Peak]              INT        NOT NULL,
    [Dashboard_Resource_Log_Time]                   DATETIME   NOT NULL,
    CONSTRAINT [PK_Dashboard_Content_Generator_Resource_Usage] PRIMARY KEY NONCLUSTERED ([Dashboard_Content_Generator_Resource_Usage_ID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Content_Generator_Resource_Usage]
    ON [dbo].[Dashboard_Content_Generator_Resource_Usage]([Dashboard_Content_Generator_Resource_Usage_ID] ASC);

