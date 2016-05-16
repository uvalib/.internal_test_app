module PublicHelper

	def file_date(date)
		return date.strftime("%m/%d/%Y")
	end

	def public_doi_link(work)
		return "Persistent link will appear here after submission." if work.draft == "true"
		return "http://dx.doi.org/#{work.identifier.gsub("doi:", "")}"
	end

	def display_rights(rights)
		return "" if rights.blank?
		rights = rights.join(" ") if rights.kind_of?(Array)
		arr = rights.split("http")
		return rights if arr.length != 2
		return content_tag("a", arr[0], { href: "http" + arr[1], target: "_blank" })
	end

	def display_related_links(links)
		a = []
		links.each { |link|
			a.push(content_tag(:a, link, { href: link, target: "_blank" }))
		}
		return raw(a.join(", "))
	end
end
