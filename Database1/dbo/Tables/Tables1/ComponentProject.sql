CREATE TABLE [dbo].[ComponentProject] (
    [ProjectName]            NVARCHAR (255)   NOT NULL,
    [ProjectID]              UNIQUEIDENTIFIER NULL,
    [ComponentProjectSource] IMAGE            NULL,
    [Version]                BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([ProjectName] ASC)
);

