'TODO: add rating to the 2nd caption line
sub init()
    print "Initializing poster"
    m.top.panelSize = "full"
    m.top.isFullScreen = true
    m.top.leftPosition = 130
    m.top.focusable = true
    m.top.hasNextPanel = false
    m.top.createNextPanelOnItemFocus = false
    m.posterWidth = 250.0
    m.top.grid = m.top.findNode("posterGrid")
    
    deviceInfo = CreateObject("roDeviceInfo")
    resolution = deviceInfo.GetUIResolution()
    physicalWidth = deviceInfo.GetDisplayProperties().Width * 10.0
    mmPixelCoef = physicalWidth / resolution.width
    
    gridRect = m.top.boundingRect()
    posterWidth = m.posterWidth * mmPixelCoef
    
    numColumns = Fix(gridRect.width / posterWidth)
    m.numColumns = numColumns
    m.top.grid.numColumns = numColumns
    
    m.top.grid.numRows = 200
    posterWidth = gridRect.width / numColumns
    m.top.grid.basePosterSize = [ posterWidth, (250 * posterWidth) / 165]
    
    m.top.observeField("start","loadCategoryPosters")
    m.top.grid.observeField("itemSelected","itemSelected")
    m.top.isVideo = false
    m.firstPage = true
end sub

sub loadCategoryPosters()
    print "loadCategoryPosters"
    m.top.grid.content = createObject("roSGNode", "ContentNode")
    m.top.overhangTitle = "Kino.pub"
    m.readPosterGridTask = createObject("roSGNode", "ContentReader")
    m.readPosterGridTask.baseUrl = m.top.gridContentBaseUri
    m.readPosterGridTask.parameters = m.top.gridContentUriParameters
    m.readPosterGridTask.observeField("content", "showPosterGrid")
    m.readPosterGridTask.control = "RUN"
end sub

sub showPosterGrid()    
    print "PosterGrid:showPosterGrid"
    
    if m.firstPage
        m.shouldPage = false
        m.totalItems = 0
        m.itemsLoaded = 0
        m.maxItemsToLoad = 1000
        m.nextPage = 1
        m.column = 0
        m.itemsPromised = m.readPosterGridTask.content.items.Count()
        if m.readPosterGridTask.content.doesExist("pagination")
            m.shouldPage = true
            m.perPage = m.readPosterGridTask.content.pagination.perpage
        end if
        
        for i=0 to m.perPage-1 step 1
            content = createObject("roSGNode", "ContentNode")
            m.top.grid.content.appendChild(content)
        end for
        
        m.rowCount = 0
    end if
    
    for each item in m.readPosterGridTask.content.items
        itemcontent = m.top.grid.content.getChild(m.itemsLoaded)
        itemcontent.setField("shortdescriptionline1", m.global.utilities.callFunc("Encode", {str: item.title}))
        itemcontent.setField("hdgridposterurl", item.posters.small)
        itemcontent.addFields({kinoPubId: item.id.ToStr(), kinoPubType: item.type})
        m.itemsLoaded = m.itemsLoaded + 1 
    end for
    
    m.nextPage = m.nextPage + 1
    m.totalItems = m.totalItems + m.readPosterGridTask.content.pagination.total_items
    
    if m.itemsPromised > m.itemsLoaded
        loadPage(m.nextPage)
    else
        m.isLoading = false
    end if
    
    if m.firstPage
        m.firstPage = false
        m.top.grid.observeField("itemFocused", "itemFocused")
        m.top.grid.setFocus(true)
        m.top.grid.visible = true
    end if
end sub

sub itemFocused()
    print "PosterGrid:itemFocused"
    itemCount = m.top.grid.content.getChildCount()
    lastRow = (itemCount-1) \ m.numColumns
    firstLastRowItem = lastRow * m.numColumns
    if m.top.grid.itemFocused >= firstLastRowItem and m.itemsLoaded < m.totalItems and m.itemsLoaded < m.maxItemsToLoad
        m.itemsPromised = m.itemsPromised + m.perPage
        for i=0 to m.perPage-1 step 1
            content = createObject("roSGNode", "ContentNode")
            m.top.grid.content.appendChild(content)
        end for
        
        if false = m.isLoading
            'If we are not loading we should kick off the loading task
            loadPage(m.nextPage)
        end if
    end if
end sub

sub loadPage(pageNumber as Integer)
    print "PosterGrid:loadPage"
    m.isLoading = true
    m.readPosterGridTask.unobserveField("content")
    m.readPosterGridTask = createObject("roSGNode", "ContentReader")
    m.readPosterGridTask.baseUrl = m.top.gridContentBaseUri
    parameters = m.top.gridContentUriParameters
    parameters.Push("page")
    parameters.Push(m.nextPage.ToStr())
    m.readPosterGridTask.parameters = parameters
    m.readPosterGridTask.observeField("content", "showPosterGrid")
    m.readPosterGridTask.control = "RUN"
end sub

sub itemSelected()
    print "PosterGrid:itemSelected"
    selectedItem = m.top.grid.content.getChild(m.top.grid.itemSelected)
    if selectedItem.kinoPubType = "movie"
        nPanel = createObject("roSGNode", "VideoDescriptionPanel")
        nPanel.itemUriParameters = ["access_token", m.global.accessToken]
        itemUrl = "https://api.service-kp.com/v1/items/" + selectedItem.kinoPubId
        nPanel.itemUri = itemUrl
        m.top.nPanel = nPanel
    else if selectedItem.kinoPubType = "serial"
        nPanel = createObject("roSGNode", "SerialGridPanel")
        nPanel.serialUriParameters = ["access_token", m.global.accessToken]
        itemUrl = "https://api.service-kp.com/v1/items/" + selectedItem.kinoPubId
        nPanel.serialBaseUri = itemUrl
        m.top.nPanel = nPanel
    end if
end sub