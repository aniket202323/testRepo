CREATE TABLE [dbo].[WorkflowResourceLink] (
    [ContainingResourceId]       UNIQUEIDENTIFIER NOT NULL,
    [ContainingResourceRevision] BIGINT           NOT NULL,
    [ContainedResourceId]        UNIQUEIDENTIFIER NOT NULL,
    [ContainedResourceRevision]  BIGINT           NULL,
    [ContainingResourceType]     NVARCHAR (255)   NULL,
    [ContainedResourceType]      NVARCHAR (255)   NULL,
    [Version]                    BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([ContainingResourceId] ASC, [ContainingResourceRevision] ASC, [ContainedResourceId] ASC)
);

