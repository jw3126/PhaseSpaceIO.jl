export iaea_download

import JSON
const IAEA_PHSP_URLS = JSON.parsefile(
    joinpath(@__DIR__, "phsplinks.json"))

function iaea_download_path(name)
    dir = abspath(joinpath(@__DIR__, "..", "download"))
    IAEAPath(joinpath(dir, name))
end

function _download(url, path, reload)
    if !ispath(path) || reload
        @info "Downloading $path"
        download(url, path)
    else
        @info "Skip download of existing file $path"
    end
end

function iaea_download(name, path::IAEAPath=iaea_download_path(name);
                      reload=false)
    urls = IAEA_PHSP_URLS[name]
    mkpath(splitdir(path.header)[1])
    mkpath(splitdir(path.phsp)[1])
    _download(urls["header"], path.header, reload)
    _download(urls["phsp"], path.phsp, reload)
    path
end
