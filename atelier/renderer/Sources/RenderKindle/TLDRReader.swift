import Foundation

enum TLDRReader {
    static func stories(in html:String,edition:URL)->[NewsItem] {
        func captures(_ pattern:String,_ text:String)->[(String,NSRange)] {
            guard let regex=try? NSRegularExpression(pattern:pattern,options:[.caseInsensitive,.dotMatchesLineSeparators]) else { return [] }
            return regex.matches(in:text,range:NSRange(text.startIndex...,in:text)).compactMap { match in
                guard let range=Range(match.range(at:1),in:text) else { return nil };return (String(text[range]),match.range)
            }
        }
        var result:[NewsItem]=[]
        for (article,_) in captures("<article\\b[^>]*>(.*?)</article>",html) {
            guard let (heading,headingRange)=captures("<h3\\b[^>]*>(.*?)</h3>",article).first else { continue }
            let rawTitle=FeedReader.clean(heading)
            guard !rawTitle.localizedCaseInsensitiveContains("(Sponsor)") else { continue }
            let title=rawTitle.replacingOccurrences(of:"\\s*\\((?:[0-9]+ minute read|GitHub Repo|Website)\\)\\s*$",with:"",options:.regularExpression)
            let body=(article as NSString).replacingCharacters(in:headingRange,with:"")
            let summary=String(FeedReader.clean(body).prefix(8000))
            guard !title.isEmpty,!summary.isEmpty else { continue }
            let link=captures("<a\\b[^>]*href=[\"']([^\"']+)[\"']",article).first?.0
            let url=link.flatMap { URL(string:FeedReader.clean($0),relativeTo:edition)?.absoluteURL }
            result.append(.init(title:title,summary:summary,link:url?.absoluteString ?? edition.absoluteString+"#article-\(result.count)"))
            if result.count==12 { break }
        }
        return result
    }
}
